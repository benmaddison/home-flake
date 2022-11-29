{ self }: { config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars));
        config = ''
          lua <<EOF
          require'nvim-treesitter.configs'.setup {
            highlight = {
              enable = true,
            },
          }
          EOF
        '';
      }
      {
        plugin = cmp-nvim-lsp;
        config = ''
          lua <<EOF
            capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)
          EOF
        '';
      }
      {
        plugin = nvim-lspconfig;
        config = ''
          lua <<EOF
          local on_attach = function(client, bufnr)
            local opts = { noremap = true, silent = true, buffer = bufnr }
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', '<M-k>', vim.lsp.buf.signature_help, opts)
          end
          require('lspconfig').rnix.setup {
            cmd = { "${pkgs.rnix-lsp}/bin/rnix-lsp" },
            on_attach = on_attach,
            capabilities = capabilities,
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
      {
        plugin = nvim-cmp;
        config = ''
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
              { name = 'luasnip' },
              { name = 'path' },
              { name = 'buffer' },
            },
            formatting = {
              format = require('lspkind').cmp_format({
                mode = "symbol_text",
                menu = ({
                  nvim_lsp = "[lsp]",
                  luasnip = "[luasnip]",
                  path = "[path]",
                  buffer = "[buffer]",
                  cmdline = "[cmd]",
                }),
              }),
            },
          }
          EOF
        '';
      }
      {
        plugin = nord-vim;
        config = ''
          colorscheme nord
        '';
      }
    ];
    extraConfig = ''
      set nocompatible
      set ignorecase
      set path+=**
      set wildmenu
      set incsearch
      set number relativenumber
      set updatetime=300
      set signcolumn=yes
      set hidden
      set expandtab
      set smarttab
      set shiftwidth=4
      set tabstop=4
      set splitbelow
      set splitright
      set laststatus=2
      set noshowmode
      set fillchars+=vert:\ 

      let mapleader='\'
      filetype plugin indent on
      syntax enable

      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      nnoremap [g vim.diagnostic.goto_prev
      nnoremap ]g vim.diagnostic.goto_next
      nnoremap <Leader>g vim.diagnostic.open_float
    '';
  };
}
