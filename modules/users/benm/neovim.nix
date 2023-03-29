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
              local opts = { noremap = true, silent = true, buffer = bufnr }
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
              vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
              vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
              vim.keymap.set('n', '<M-k>', vim.lsp.buf.signature_help, opts)
              vim.api.nvim_create_autocmd({'BufWritePre'}, {
                pattern = '*',
                callback = function() vim.lsp.buf.formatting_seq_sync() end,
              })
            end

            local lspconfig = require('lspconfig')

            lspconfig.rnix.setup {
              cmd = { '${pkgs.rnix-lsp}/bin/rnix-lsp' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            }

            local lua_runtime_path = vim.split(package.path, ';')
            table.insert(lua_runtime_path, 'lua/?.lua')
            table.insert(lua_runtime_path, 'lua/?/init.lua')
            lspconfig.sumneko_lua.setup {
              cmd = { '${pkgs.sumneko-lua-language-server}/bin/lua-language-server' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
              settings = {
                Lua = {
                  runtime = {
                    version = 'LuaJIT',
                    path = lua_runtime_path,
                  },
                  diagnostics = {
                    globals = { 'vim' },
                  },
                  workspace = {
                    checkThirdParty = false,
                    library = vim.api.nvim_get_runtime_file("", true),
                  },
                  telemetry = {
                    enable = false,
                  },
                },
              },
            }

            lspconfig.pyright.setup {
              cmd = { '${pkgs.pyright}/bin/pyright-langserver', '--stdio' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            }

            lspconfig.rust_analyzer.setup {
              on_attach = function(client, bufnr)
                lsp_on_attach(client, bufnr)
                local opts = { noremap = true, silent = true, buffer = bufnr }
                vim.keymap.set('n', '<leader>rr', '<cmd>FloatermNew --autoclose=0 cargo run<cr>', opts)
                vim.keymap.set('n', '<leader>rt', '<cmd>FloatermNew --autoclose=0 cargo test<cr>', opts)
                vim.keymap.set('n', '<leader>rc', '<cmd>FloatermNew --autoclose=0 cargo check<cr>', opts)
              end,
              capabilities = lsp_capabilities,
              settings = {
                ['rust-analyzer'] = {
                  cargo = {
                    features = 'all',
                  },
                },
              },
            }
            EOF
          '';
        }

        # TODO: re-enable once https://github.com/simrat39/rust-tools.nvim/issues/312
        #       is fixed in nixpkgs-stable
        #
        # {
        #   plugin = rust-tools-nvim;
        #   config = self.lib.code "vim" ''
        #     lua <<EOF
        #     local rt = require('rust-tools')
        #     rt.setup({
        #       server = {
        #         on_attach = function(client, bufnr)
        #           lsp_on_attach(client, bufnr)
        #           -- Hover actions
        #           vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
        #           -- Code action groups
        #           vim.keymap.set('n', '<leader>a', rt.code_action_group.code_action_group, { buffer = bufnr })
        #           -- Cargo run
        #           vim.keymap.set('n', '<leader>rr', '<cmd>FloatermNew --autoclose=0 cargo run<cr>', {})
        #           vim.keymap.set('n', '<leader>rt', '<cmd>FloatermNew --autoclose=0 cargo test<cr>', {})
        #           vim.keymap.set('n', '<leader>rc', '<cmd>FloatermNew --autoclose=0 cargo check<cr>', {})
        #         end,
        #       },
        #     })
        #     EOF
        #   '';
        # }

        cmp-buffer
        cmp-path
        cmp-cmdline
        luasnip
        cmp_luasnip
        lspkind-nvim
        cmp-nvim-lsp-signature-help
        cmp-nvim-lua
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
                { name = 'path' },
                { name = 'buffer' },
              },
              formatting = {
                format = require('lspkind').cmp_format({
                  mode = "symbol_text",
                  menu = ({
                    nvim_lsp = '[lsp]',
                    luasnip = '[luasnip]',
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
                    },
                  },
                },
              },
            }
            telescope.load_extension('fzf')
            telescope.load_extension('file_browser')
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>pp', builtin.find_files, {})
            vim.keymap.set('n', '<leader>pf', builtin.live_grep, {})
            vim.keymap.set('n', '<leader>pb', builtin.buffers, {})
            vim.keymap.set('n', '<leader>ph', builtin.help_tags, {})
            vim.keymap.set('n', '<leader>pF', builtin.filetypes, {})
            vim.keymap.set('n', '<leader>pP', builtin.builtin, {})
            vim.keymap.set('n', '<leader>g', builtin.diagnostics, {})
            vim.keymap.set('n', '<leader>f', telescope.extensions.file_browser.file_browser, {})
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
                vim.keymap.set('n', '<leader>a', picker, {})
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
            vim.keymap.set('n', '<leader>tt', '<cmd>FloatermNew<cr>', {})
            vim.keymap.set('n', '<leader>tn', '<cmd>FloatermNew nix repl<cr>', {})
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

                local function map(mode, l, r, opts)
                  opts = opts or {}
                  opts.buffer = bufnr
                  vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', ']c', function()
                  if vim.wo.diff then return ']c' end
                  vim.schedule(function() gs.next_hunk() end)
                  return '<Ignore>'
                end, {expr=true})

                map('n', '[c', function()
                  if vim.wo.diff then return '[c' end
                  vim.schedule(function() gs.prev_hunk() end)
                  return '<Ignore>'
                end, {expr=true})

                -- Actions
                map({'n', 'v'}, '<leader>hs', '<cmd>Gitsigns stage_hunk<cr>')
                map({'n', 'v'}, '<leader>hr', '<cmd>Gitsigns reset_hunk<cr>')
                map('n', '<leader>hS', gs.stage_buffer)
                map('n', '<leader>hu', gs.undo_stage_hunk)
                map('n', '<leader>hR', gs.reset_buffer)
                map('n', '<leader>hp', gs.preview_hunk)
                map('n', '<leader>hb', function() gs.blame_line{full=true} end)
                map('n', '<leader>hB', gs.toggle_current_line_blame)
                map('n', '<leader>hd', gs.diffthis)
                map('n', '<leader>hD', gs.toggle_deleted)
              end
            }
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

        vim.keymap.set('n', '<C-h>', '<C-w>h', {})
        vim.keymap.set('n', '<C-j>', '<C-w>j', {})
        vim.keymap.set('n', '<C-k>', '<C-w>k', {})
        vim.keymap.set('n', '<C-l>', '<C-w>l', {})

        vim.diagnostic.config({
          virtual_text = false,
          signs = true,
          update_in_insert = true,
        })
        vim.o.signcolumn = 'yes'
        vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, {})
        vim.keymap.set('n', ']g', vim.diagnostic.goto_next, {})
        vim.keymap.set('n', '<C-M-K>', vim.diagnostic.open_float, {})

        vim.keymap.set('n', '<leader>/', '<cmd>let @/ = ""<cr>', {})
        EOF
      '';
    };
  };
}
