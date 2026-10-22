{
  config,
  pkgs,
  lib,
  ...
}:

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
          # TODO:
          # drop this once https://github.com/nvim-treesitter/nvim-treesitter/pull/4658
          # makes it into nixpkgs-stable
          nix.injections = /* query */ ''
            ;; extends
            ((((comment) @injection.language) .
             (indented_string_expression (string_fragment) @injection.content))
             (#gsub! @injection.language "/%*%s*(%w+)%s*%*/" "%1")
             (#set! injection.combined))
          '';
          lua.highlights = /* query */ ''
            ;; extends
            (string) @nospell
          '';
        };
        path = lang: module: "nvim/after/queries/${lang}/${module}.scm";
        writeQuery = lang: mod: src: { source = pkgs.writeText "${lang}-${mod}.scm" src; };
        makeQuery =
          lang: mod: src:
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
      withRuby = false;
      withPython3 = false;
      extraPackages = with pkgs; [
        tree-sitter
      ];
      plugins = with pkgs.vimPlugins; [
        nvim-web-devicons
        {
          plugin = mini-icons;
          type = "lua";
          config = /* lua */ ''
            require('mini.icons').setup({})
          '';
        }
        {
          plugin = which-key-nvim;
          type = "lua";
          config = /* lua */ ''
            wk = require('which-key')
            wk.setup()
            wk.add({
              { '<C-h>', '<C-w>h', desc = "Move to left window"},
              { '<C-j>', '<C-w>j', desc = "Move to down window"},
              { '<C-k>', '<C-w>k', desc = "Move to up window"},
              { '<C-l>', '<C-w>l', desc = "Move to right window"},
              { '[g', function() vim.diagnostic.goto_prev() end, desc = "Previous diagnostic" },
              { ']g', function() vim.diagnostic.goto_next() end, desc = "Next diagnostic" },
              { '<C-M-K>', function() vim.diagnostic.open_float() end, desc = "Show diagnostic" },
              { '<leader>/', '<cmd>let @/ = ""<cr>', desc = "Clear search pattern register" },
              { '<leader>?', '<cmd>WhichKey<cr>', desc = "Open which-key hints" },
              { 'g', group = '+goto' },
            })
          '';
        }

        {
          plugin = nvim-treesitter.withAllGrammars;
          type = "lua";
          config = /* lua */ ''
            vim.api.nvim_create_autocmd('FileType', {
              callback = function(event)
                -- check that a treesitter parser is available for the buffer
                local filetype = vim.bo[event.buf].filetype
                local lang = vim.treesitter.language.get_lang(filetype)
                if vim.treesitter.language.add(lang, {}) then
                  -- highlighting
                  vim.treesitter.start()
                  -- folding
                  vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                  vim.wo[0][0].foldmethod = 'expr'
                  -- TODO:
                  -- indendation
                  -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
              end,
            })
          '';
        }
        {
          plugin = nvim-ts-context-commentstring;
          type = "lua";
          config = /* lua */ ''
            require('ts_context_commentstring').setup {
              enable_autocmd = false,
              languages = {
                query = '; %s',
              }
            }
          '';
        }
        {
          plugin = comment-nvim;
          type = "lua";
          config = /* lua */ ''
            require('Comment').setup({
              pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
            })
          '';
        }

        cmp-nvim-lsp
        {
          plugin = nvim-lspconfig;
          type = "lua";
          config = /* lua */ ''
            lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
            lsp_on_attach = function(client, bufnr)
              wk.add({
                {
                  buffer = bufnr,
                  { 'gd', function() vim.lsp.buf.definition() end, desc = "LSP definition" },
                  { 'gD', function() vim.lsp.buf.declaration() end, desc = "LSP declaration" },
                  { 'gt', function() vim.lsp.buf.type_definition() end, desc = "LSP type definition" },
                  { 'gi', function() vim.lsp.buf.implementation() end, desc = "LSP implementations" },
                  { 'K', function() vim.lsp.buf.hover() end, desc = "Show LSP information" },
                  { '<M-k>', function() vim.lsp.buf.signature_help() end, desc = "Show LSP signature help" },
                }
              })
              vim.api.nvim_create_autocmd({'BufWritePre'}, {
                pattern = '*',
                callback = function() vim.lsp.buf.format() end,
              })
            end

            vim.lsp.config('lua_ls', {
              cmd = { '${pkgs.luaPackages.lua-lsp}/bin/lua-lsp' },
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
            })
            vim.lsp.enable('lua_ls')

            vim.lsp.config('pyright', {
              cmd = { '${pkgs.pyright}/bin/pyright-langserver', '--stdio' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            })
            vim.lsp.enable('pyright')

            vim.lsp.config('rust_analyzer', {
              on_attach = function(client, bufnr)
                lsp_on_attach(client, bufnr)
                wk.add({
                  {
                    buffer = bufnr,
                    { '<leader>r', group = "+cargo" },
                    {
                      '<leader>rr',
                      '<cmd>FloatermNew --autoclose=0 cargo run<cr>',
                      desc = "cargo run",
                    },
                    {
                      '<leader>rt',
                      '<cmd>FloatermNew --autoclose=0 cargo test --all --all-features<cr>',
                      desc = "cargo test",
                    },
                    {
                      '<leader>rc',
                      '<cmd>FloatermNew --autoclose=0 cargo clippy --all --all-features --all-targets<cr>',
                      desc = "cargo clippy",
                    },
                  },
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
            })
            vim.lsp.enable('rust_analyzer')

            vim.lsp.config('marksman', {
                cmd = { '${pkgs.marksman}/bin/marksman', 'server' },
            })
            vim.lsp.enable('marksman')

            vim.lsp.config('nil_ls', {
              cmd = { '${pkgs.nil}/bin/nil' },
              on_attach = function(client, bufnr)
                lsp_on_attach(client, bufnr)
                wk.add({
                  {
                    buffer = bufnr,
                    { '<leader>n', group = '+nix' },
                    {
                      '<leader>nc',
                      '<cmd>FloatermNew --autoclose=0 nix flake check<cr>',
                      desc = "flake check",
                    },
                  },
                })
              end,
              capabilities = lsp_capabilities,
            })
            vim.lsp.enable('nil_ls')
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
          type = "lua";
          config = /* lua */ ''
            require('cmp_git').setup()
          '';
        }
        {
          plugin = nvim-cmp;
          type = "lua";
          config = /* lua */ ''
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
          '';
        }

        {
          plugin = onenord-nvim;
          type = "lua";
          config = /* lua */ ''
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
          '';
        }

        telescope-fzf-native-nvim
        telescope-file-browser-nvim
        telescope-lsp-handlers-nvim
        {
          plugin = telescope-nvim;
          type = "lua";
          config = /* lua */ ''
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
            wk.add({
              { '<leader>g', function() builtin.diagnostics() end, desc = "Show diagnostics" },
              { '<leader>f', function() telescope.extensions.file_browser.file_browser() end, desc = "Show file browser" },
              { '<leader>p', group = '+pickers' },
              { '<leader>pp', function() builtin.find_files() end, desc = "Workspace files" },
              { '<leader>pf', function() builtin.live_grep() end, desc = "Workspace line grep" },
              { '<leader>pb', function() builtin.buffers() end, desc = "Open buffers" },
              { '<leader>pB', function() builtin.current_buffer_fuzzy_find() end, desc = "Current buffer line grep" },
              { '<leader>ps', function() builtin.lsp_dynamic_workspace_symbols() end, desc = "Workspace LSP symbols" },
              { '<leader>ph', function() builtin.help_tags() end, desc = "Help tags" },
              { '<leader>pF', function() builtin.filetypes() end, desc = "File types" },
              { '<leader>pk', function() builtin.keymaps() end, desc = "Keymaps" },
              { '<leader>pg', function() builtin.git_status() end, desc = "Git status" },
              { '<leader>pP', function() builtin.builtin() end, desc = "Built-in telescope pickers" },
            })
            -- TODO:
            -- attachment-picker
            vim.api.nvim_create_autocmd({'FileType'}, {
              pattern = 'mail',
              callback = function(event)
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
                      action_sets.select:replace_if(
                        function()
                          local entry = state.get_selected_entry()
                          return entry and not entry.Path:is_dir()
                        end,
                        function()
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
                        end
                      )
                      return true
                    end
                  }
                end
                wk.add({
                  { '<leader>a', function() picker() end, desc = "Add attachments", buffer = event.buf },
                })
              end,
            })
          '';
        }

        {
          plugin = pears-nvim;
          type = "lua";
          config = /* lua */ ''
            require('pears').setup()
          '';
        }

        {
          plugin = nvim-surround;
          type = "lua";
          config = /* lua */ ''
            require('nvim-surround').setup({})
          '';
        }

        {
          plugin = vim-floaterm;
          type = "lua";
          config = /* lua */ ''
            wk.add({
              { '<leader>t', group = '+terminals' },
              { '<leader>tt', '<cmd>FloatermNew<cr>', desc = "shell" },
              { '<leader>tn', '<cmd>FloatermNew nix repl<cr>', desc = "nix repl" },
            })
          '';
        }

        {
          plugin = gitsigns-nvim;
          type = "lua";
          config = /* lua */ ''
            require('gitsigns').setup{
              on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                wk.add({
                  {
                    buffer = bufnr,
                    {
                      '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(function() gs.prev_hunk() end)
                        return '<Ignore>'
                      end,
                      desc = "Previous unstaged hunk",
                    },
                    {
                      ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(function() gs.next_hunk() end)
                        return '<Ignore>'
                      end,
                      desc = "Next unstaged hunk",
                    },
                    { '<leader>h', group = '+git' },
                    {
                      mode = { 'n', 'v' },
                      { '<leader>hs', '<cmd>Gitsigns stage_hunk<cr>', desc = "Stage hunk", mode = {'n', 'v'} },
                      { '<leader>hr', '<cmd>Gitsigns reset_hunk<cr>', desc = "Reset hunk", mode = {'n', 'v'} },
                    },
                    { '<leader>hS', function() gs.stage_buffer() end, desc = "Stage buffer" },
                    { '<leader>hR', function() gs.reset_buffer() end, desc = "Reset buffer" },
                    { '<leader>hu', function() gs.undo_stage_hunk() end, desc = "Undo stage hunk" },
                    { '<leader>hp', function() gs.preview_hunk() end, desc = "Preview hunk" },
                    { '<leader>hb', function() gs.blame_line({full=true}) end, desc = "Show blame" },
                    { '<leader>hB', function() gs.toggle_current_line_blame() end, desc = "Toggle blame hints" },
                    { '<leader>hd', function() gs.diffthis() end, desc = "Diff current buffer" },
                    { '<leader>hD', function() gs.toggle_deleted() end, desc = "Toggle deleted" },
                  },
                })
              end
            }
          '';
        }

        {
          plugin = lualine-nvim;
          type = "lua";
          config = /* lua */ ''
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
          '';
        }

        {
          plugin = fidget-nvim;
          type = "lua";
          config = /* lua */ ''
            require('fidget').setup {
              notification = {
                window = {
                  winblend = 0,
                  border = 'single',
                },
              },
            }
          '';
        }

        {
          plugin = octo-nvim;
          type = "lua";
          config = /* lua */ ''
            require('octo').setup {}
            wk.add({
              { '<leader>o', group = '+octo' },
              { '<leader>oi', '<cmd>Octo issue list<cr>', desc = 'List github issues' },
              { '<leader>op', '<cmd>Octo pr list<cr>', desc = 'List github pull-requests' },
              { '<leader>oa', '<cmd>Octo actions<cr>', desc = 'List available octo actions' },
            })
          '';
        }
      ];

      initLua = /* lua */ ''
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
      '';
    };
  };
}
