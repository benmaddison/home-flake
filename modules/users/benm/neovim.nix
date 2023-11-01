{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.neovim;
in
{
  options.local.neovim = {
    enable = lib.mkEnableOption "enable neovim";
  };

  config = lib.mkIf cfg.enable {

    xdg.configFile =
      let
        treesitterQueries = {
          nix.injections = self.lib.code "query" ''
            ;; extends
            ((apply_expression
              function: (apply_expression
                function: (_) @_func
                argument: (string_expression (string_fragment) @language))
              argument: [
                (string_expression (string_fragment) @content)
                (indented_string_expression (string_fragment) @content)
              ])
              (#match? @_func "(^|\\.)code"))
              @combined
          '';
          lua.highlights = self.lib.code "query" ''
            ;; extends
            (string) @nospell
          '';
        };
        path = lang: module: "nvim/after/queries/${lang}/${module}.scm";
        writeQuery = lang: mod: src:
          { source = pkgs.writeText "${lang}-${mod}.scm" src; };
        makeQuery = lang: mod: src:
          lib.nameValuePair (path lang mod) (writeQuery lang mod src);
        queriesFor = lang: mods: lib.mapAttrs' (makeQuery lang) mods;
        queries = lib.mapAttrsToList queriesFor treesitterQueries;
      in
      lib.foldl' (a: b: a // b) { } queries;

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        nvim-web-devicons

        {
          plugin = which-key-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            wk = require('which-key')
            wk.setup {
              operators = {
                ys = "Create surround",
                cs = "Change surround",
                ds = "Delete surround",
                gc = "Line comment",
                gb = "Block comment",
              }
            }
            wk.register({
              ['<C-h>'] = { '<C-w>h', "Move to left window"},
              ['<C-j>'] = { '<C-w>j', "Move to down window"},
              ['<C-k>'] = { '<C-w>k', "Move to up window"},
              ['<C-l>'] = { '<C-w>l', "Move to right window"},
              ['[g'] = { function() vim.diagnostic.goto_prev() end, "Previous diagnostic" },
              [']g'] = { function() vim.diagnostic.goto_next() end, "Next diagnostic" },
              ['<C-M-K>'] = { function() vim.diagnostic.open_float() end, "Show diagnostic" },
              ['<leader>/'] = { '<cmd>let @/ = ""<cr>', "Clear search pattern register" },
              ['<leader>?'] = { '<cmd>WhichKey<cr>', "Open which-key hints" },
            })
            EOF
          '';
        }

        playground
        nvim-ts-context-commentstring
        {
          plugin = nvim-treesitter.withAllGrammars;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('nvim-treesitter.configs').setup {
              highlight = {
                enable = true,
              },
              indent = {
                enable = true,
              },
              playground = {
                enable = true,
              },
              query_linter = {
                enable = true,
              },
              context_commentstring = {
                enable = true,
                enable_autocommand = false,
                config = {
                  query = '; %s',
                },
              },
            }
            vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
            EOF
          '';
        }
        {
          plugin = comment-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('Comment').setup({
              pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
            })
            EOF
          '';
        }

        cmp-nvim-lsp
        {
          plugin = nvim-lspconfig;
          config = self.lib.code "vim" ''
            lua <<EOF
            lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
            lsp_on_attach = function(client, bufnr)
              wk.register({
                g = {
                  name = '+goto',
                  d = { function() vim.lsp.buf.definition() end, "LSP definition" },
                  D = { function() vim.lsp.buf.declaration() end, "LSP declaration" },
                  t = { function() vim.lsp.buf.type_definition() end, "LSP type definition" },
                  i = { function() vim.lsp.buf.implementation() end, "LSP implementations" },
                  r = { function() vim.lsp.buf.references() end, "LSP references" },
                },
                K = { function() vim.lsp.buf.hover() end, "Show LSP information" },
                ['<M-k>'] = { function() vim.lsp.buf.signature_help() end, "Show LSP signature help" },
              }, {
                buffer = bufnr,
              })
              vim.api.nvim_create_autocmd({'BufWritePre'}, {
                pattern = '*',
                callback = function() vim.lsp.buf.format() end,
              })
            end

            local lspconfig = require('lspconfig')

            lspconfig.rnix.setup {
              cmd = { '${pkgs.rnix-lsp}/bin/rnix-lsp' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            }

            lspconfig.lua_ls.setup {
              cmd = { '${pkgs.luaPackages.lua-lsp}/bin/lua-language-server'},
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
              on_init = function(client)
                local path = client.workspace_folders[1].name
                if
                  not vim.loop.fs_stat(path..'/.luarc.json') and
                  not vim.loop.fs_stat(path..'/.luarc.jsonc')
                then
                  client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
                    Lua = {
                      runtime = {
                        version = 'LuaJIT'
                      },
                      workspace = {
                        checkThirdParty = false,
                        library = {
                          vim.env.VIMRUNTIME
                        }
                      }
                    }
                  })

                  client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                end
                return true
              end
            }

            lspconfig.pyright.setup {
              cmd = { '${pkgs.pyright}/bin/pyright-langserver', '--stdio' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            }

            lspconfig.rust_analyzer.setup {
              cmd = { 'rustup', 'run', 'nightly', 'rust-analyzer'},
              on_attach = function(client, bufnr)
                lsp_on_attach(client, bufnr)
                wk.register({
                  name = '+rust-cargo',
                  r = { '<cmd>FloatermNew --autoclose=0 cargo run<cr>', "cargo run" },
                  t = { '<cmd>FloatermNew --autoclose=0 cargo test --all --all-features<cr>', "cargo test" },
                  c = { '<cmd>FloatermNew --autoclose=0 cargo clippy --all --all-features --all-targets<cr>', "cargo clippy" },
                }, {
                  prefix = '<leader>r',
                  buffer = bufnr,
                })
              end,
              capabilities = lsp_capabilities,
              settings = {
                ['rust-analyzer'] = {
                  cargo = {
                    features = 'all',
                  },
                  check = {
                    command = 'clippy',
                    features = 'all',
                  },
                },
              },
            }

            lspconfig.marksman.setup {
              cmd = { '${pkgs.marksman}/bin/marksman', 'server' },
            }
            EOF
          '';
        }

        cmp-buffer
        cmp-path
        cmp-cmdline
        luasnip
        cmp_luasnip
        lspkind-nvim
        cmp-nvim-lsp-signature-help
        cmp-nvim-lua
        {
          plugin = cmp-git;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('cmp_git').setup()
            EOF
          '';
        }
        {
          plugin = nvim-cmp;
          config = self.lib.code "vim" ''
            lua <<EOF
            local cmp = require('cmp')
            cmp.setup {
              mapping = cmp.mapping.preset.insert({
                ['<C-d>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>'] = cmp.mapping.confirm{
                  behaviour = cmp.ConfirmBehavior.Replace,
                  select = true,
                },
                ['<Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
              }),
              snippet = {
                expand = function(args)
                  require('luasnip').lsp_expand(args.body)
                end,
              },
              sources = {
                { name = 'nvim_lsp' },
                { name = 'nvim_lsp_signature_help'},
                { name = 'nvim_lua'},
                { name = 'luasnip' },
                { name = 'git' },
                { name = 'path' },
                { name = 'buffer' },
              },
              formatting = {
                format = require('lspkind').cmp_format({
                  mode = "symbol_text",
                  menu = ({
                    nvim_lsp = '[lsp]',
                    luasnip = '[luasnip]',
                    git = '[github]',
                    path = '[path]',
                    buffer = '[buffer]',
                    cmdline = '[cmd]',
                  }),
                }),
              },
              window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
              },
            }
            EOF
          '';
        }

        {
          plugin = onenord-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('onenord').setup({
              theme = 'dark',
              styles = {
                diagnostics = 'undercurl',
                comments = 'italic',
                strings = 'italic',
                functions = 'bold',
              },
              disable = {
                background = true,
              },
            })
            EOF
          '';
        }

        telescope-fzf-native-nvim
        telescope-file-browser-nvim
        telescope-lsp-handlers-nvim
        {
          plugin = telescope-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            local telescope = require('telescope')
            local actions = require('telescope.actions')
            telescope.setup {
              defaults = {
                mappings = {
                  i = {
                    ["<C-S>"] = actions.select_horizontal,
                  },
                  n = {
                    ["<C-S>"] = actions.select_horizontal,
                    ["l"] = actions.select_default,
                  },
                },
              },
              extensions = {
                file_browser = {
                  initial_mode = "normal",
                  prompt_prefix = "/",
                  grouped = true,
                  hidden = true,
                  theme = "ivy",
                  mappings = {
                    n = {
                      ["h"] = telescope.extensions.file_browser.actions.goto_parent_dir,
                      ["<space>"] = actions.toggle_selection,
                      ["/"] = { "i", type = 'command' },
                    },
                  },
                },
              },
            }
            telescope.load_extension('fzf')
            telescope.load_extension('file_browser')
            telescope.load_extension('lsp_handlers')
            local builtin = require('telescope.builtin')
            wk.register({
              p = {
                name = '+pick',
                p = { function() builtin.find_files() end, "Workspace files" },
                f = { function() builtin.live_grep() end, "Workspace line grep" },
                b = { function() builtin.buffers() end, "Open buffers" },
                B = { function() builtin.current_buffer_fuzzy_find() end, "Current buffer line grep" },
                s = { function() builtin.lsp_dynamic_workspace_symbols() end, "Workspace LSP symbols" },
                h = { function() builtin.help_tags() end, "Help tags" },
                F = { function() builtin.filetypes() end, "File types" },
                k = { function() builtin.keymaps() end, "Keymaps" },
                P = { function() builtin.builtin() end, "Built-in telescope pickers" },
              },
              g = { function() builtin.diagnostics() end, "Show diagnostics" },
              f = { function() telescope.extensions.file_browser.file_browser() end, "Show file browser" },
            }, {
              prefix = '<leader>',
            })
            -- attachment-picker
            vim.api.nvim_create_autocmd({'FileType'}, {
              pattern = 'mail',
              callback = function()
                local actions = require('telescope.actions')
                local action_sets = require('telescope.actions.set')
                local state = require('telescope.actions.state')
                local utils = require('telescope.actions.utils')
                local ns = vim.api.nvim_create_namespace("attachment-picker")
                local picker = function()
                  local save_cursor = function()
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    return vim.api.nvim_buf_set_extmark(0, ns, cursor[1], cursor[2], {})
                  end
                  local restore_cursor = function(mark)
                    local pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, mark, {})
                    vim.api.nvim_win_set_cursor(0, pos)
                    return vim.api.nvim_buf_del_extmark(0, ns, mark)
                  end
                  local position = save_cursor()
                  telescope.extensions.file_browser.file_browser {
                    attach_mappings = function(prompt_buf, _)
                      action_sets.select:replace_if(function()
                        local entry = state.get_selected_entry()
                        return entry and not entry.Path:is_dir()
                      end, function()
                        local selections = {}
                        utils.map_selections(prompt_buf, function(entry, _)
                          local path = string.format("Attach: %s", entry.value)
                          table.insert(selections, path)
                        end)
                        actions.close(prompt_buf)
                        vim.api.nvim_win_set_cursor(0, { 1, 0 })
                        vim.fn.search("Subject:", "c")
                        vim.api.nvim_put(selections, "l", true, false)
                        restore_cursor(position)
                      end)
                      return true
                    end
                  }
                end
                wk.register({
                  a = { function() picker() end, "Add attachments" },
                }, {
                  buffer = true,
                  prefix = '<leader>',
                })
              end,
            })
            EOF
          '';
        }

        {
          plugin = pears-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('pears').setup()
            EOF
          '';
        }

        {
          plugin = nvim-surround;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('nvim-surround').setup({})
            EOF
          '';
        }

        {
          plugin = vim-floaterm;
          config = self.lib.code "vim" ''
            lua <<EOF
            wk.register({
              t = {
                name = '+terminal',
                t = { '<cmd>FloatermNew<cr>', "Shell" },
                n = { '<cmd>FloatermNew nix repl<cr>', "nix repl" },
              },
            }, {
              prefix = '<leader>',
            })
            EOF
          '';
        }

        {
          plugin = gitsigns-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('gitsigns').setup{
              on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                wk.register({
                  ['[c'] = {
                    function()
                      if vim.wo.diff then return '[c' end
                      vim.schedule(function() gs.prev_hunk() end)
                      return '<Ignore>'
                    end,
                    "Previous unstaged hunk",
                    expr = true,
                  },
                  [']c'] = {
                    function()
                      if vim.wo.diff then return ']c' end
                      vim.schedule(function() gs.next_hunk() end)
                      return '<Ignore>'
                    end,
                    "Next unstaged hunk",
                    expr = true,
                  },
                }, {
                  buffer = bufnr,
                })
                wk.register({
                  h = {
                    name = '+git',
                    s = { '<cmd>Gitsigns stage_hunk<cr>', "Stage hunk", mode = {'n', 'v'} },
                    r = { '<cmd>Gitsigns reset_hunk<cr>', "Reset hunk", mode = {'n', 'v'} },
                    S = { function() gs.stage_buffer() end, "Stage buffer" },
                    R = { function() gs.reset_buffer() end, "Reset buffer" },
                    u = { function() gs.undo_stage_hunk() end, "Undo stage hunk" },
                    p = { function() gs.preview_hunk() end, "Preview hunk" },
                    b = { function() gs.blame_line({full=true}) end, "Show blame" },
                    B = { function() gs.toggle_current_line_blame() end, "Toggle blame hints" },
                    d = { function() gs.diffthis() end, "Diff current buffer" },
                    D = { function() gs.toggle_deleted() end, "Toggle deleted" },
                  }
                }, {
                  prefix = '<leader>',
                  buffer = bufnr,
                })
              end
            }
            EOF
          '';
        }

        {
          plugin = lualine-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('lualine').setup {
              options = {
                theme = 'onenord',
                section_separators = "",
                component_separators = '┃',
                sections = {
                  lualine_c = {'filename', path = 1, newfile_status = true},
                },
              },
            }
            vim.o.cmdheight = 0
            EOF
          '';
        }

        {
          plugin = fidget-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('fidget').setup {
              window = {
                blend = 0,
                border = 'single',
              },
            }
            EOF
          '';
        }

        {
          plugin = octo-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            require('octo').setup {}
            EOF
          '';
        }
      ];

      extraConfig = self.lib.code "vim" ''
        lua <<EOF
        vim.o.expandtab = true
        vim.o.hidden = true
        vim.o.ignorecase = true
        vim.o.incsearch = true
        vim.o.laststatus = 2
        vim.o.number = true
        vim.o.relativenumber = true
        vim.o.shiftwidth = 4
        vim.o.showmode = false
        vim.o.smarttab = true
        vim.o.spell = true
        vim.o.splitbelow = true
        vim.o.splitright = true
        vim.o.tabstop = 4
        vim.o.updatetime = 300
        vim.o.wildmenu = true

        vim.o.foldmethod = 'expr'
        vim.o.foldenable = false

        vim.opt.path:append('**')

        vim.cmd.filetype('plugin indent on')
        vim.cmd.syntax('enable')

        vim.diagnostic.config({
          virtual_text = false,
          signs = true,
          update_in_insert = true,
        })
        vim.o.signcolumn = 'yes'
        EOF
      '';
    };
  };
}
