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
            require('lspconfig').rnix.setup {
              cmd = { '${pkgs.rnix-lsp}/bin/rnix-lsp' },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            }
            EOF
          '';
        }

        {
          plugin = rust-tools-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            local rt = require('rust-tools')
            rt.setup({
              server = {
                on_attach = function(client, bufnr)
                  lsp_on_attach(client, bufnr)
                  -- Hover actions
                  vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
                  -- Code action groups
                  vim.keymap.set('n', '<leader>a', rt.code_action_group.code_action_group, { buffer = bufnr })
                  -- Cargo run
                  vim.keymap.set('n', '<leader>rr', '<cmd>FloatermNew --autoclose=0 cargo run<cr>', {})
                  vim.keymap.set('n', '<leader>rt', '<cmd>FloatermNew --autoclose=0 cargo test<cr>', {})
                end,
              },
            })
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
        {
          plugin = telescope-nvim;
          config = self.lib.code "vim" ''
            lua <<EOF
            local telescope = require('telescope')
            telescope.setup{}
            telescope.load_extension('fzf')
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>pp', builtin.find_files, {})
            vim.keymap.set('n', '<leader>pf', builtin.live_grep, {})
            vim.keymap.set('n', '<leader>pb', builtin.buffers, {})
            vim.keymap.set('n', '<leader>ph', builtin.help_tags, {})
            vim.keymap.set('n', '<leader>pF', builtin.filetypes, {})
            vim.keymap.set('n', '<leader>pP', builtin.builtin, {})
            vim.keymap.set('n', '<leader>g', builtin.diagnostics, {})
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

        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

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
        vim.api.nvim_create_autocmd({'CursorHold'}, {
          pattern = '*',
          callback = function() vim.diagnostic.open_float() end,
        })

        vim.keymap.set('n', '<leader>/', '<cmd>let @/ = ""<cr>', {})
        EOF
      '';
    };
  };
}
