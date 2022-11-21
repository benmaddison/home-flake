{ config, pkgs, lib, impermanence, ... }:

let
  colors = {
    black        = "#2e3440";
    red          = "#bf616a";
    green        = "#a3be8c";
    orange       = "#d08770";
    blue         = "#5e81ac";
    magenta      = "#b48ead";
    cyan         = "#88c0d0";
    light-grey   = "#d8dee9";
    dark-grey    = "#4c566a";
    light-red    = "#bf616a";
    light-green  = "#a3be8c";
    yellow       = "#ebcb8b";
    light-blue   = "#81a1c1";
    light-purple = "#b48ead";
    teal         = "#8fbcbb";
    white        = "#eceff4";
  };
in {
  home.username = "benm";
  home.homeDirectory = "/home/benm";
  home.stateVersion = "22.05";

  imports = [ impermanence ];

  home.persistence."/data/user/benm" = {
    allowOther = true;
    files = [
      ".config/gh/hosts.yml"
    ];
    directories = [
      "documents"
      "downloads"
      "media"
      ".cache"
      ".config/keybase"
      ".local/share"
      ".mozilla/firefox/default"
    ];
  };

  home.packages = with pkgs; [
    du-dust
    fd
    libsecret
    nerdfonts
    ripgrep
    w3m
  ];

  fonts.fontconfig.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {
      colors = with colors; {
        primary = {
          background = black;
          foreground = light-grey;
        };
        search = {
          matches = {
            background = cyan;
            foreground = black;
          };
          bar = {
            background = cyan;
            foreground = black;
          };
        };
        normal = {
          inherit black red green yellow blue magenta cyan white;
        };
        bright = {
          inherit red green magenta;
          black = dark-grey;
          yellow = orange;
          blue = light-blue;
          cyan = teal;
          white = light-grey;
        };
      };
      font = {
        normal.family = "SauceCodePro Nerd Font";
        size = 12;
      };
    };
  };

  programs.bash = {
    enable = true;
    # TODO: this doesn't seem to work - check docs
    historyFile = "${config.xdg.dataHome}/bash/history";
    historyControl = [ "ignoredups" "ignorespace" ];
    shellAliases = {
      ".." = ''cd ..'';
      "..." = ''cd "$(git root || echo -n .)"'';
      "cat" = ''bat'';
      "du" = ''dust'';
      "grep" = ''grep --color=auto'';
      "fgrep" = ''fgrep --color=auto'';
      "egrep" = ''egrep --color=auto'';
      "xc"  = ''xclip -selection clipboard'';
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Nord";
      style = "header,numbers,changes";
      italic-text = "always";
      paging = "auto";
    };
  };

  programs.bottom.enable = true;

  programs.broot.enable = true;

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  programs.firefox = {
    enable = true;
    profiles.default = {};
  };

  programs.fzf = let
    fd = type: "${pkgs.fd}/bin/fd --type ${type} --hidden --follow --exclude .git";
  in {
    enable = true;
    defaultCommand = fd "file";
    defaultOptions = [
      "--reverse"
      "--height 40%"
      "--border"
      "--margin 0,2"
      "--inline-info"
      "--color 'fg:-1,bg:-1,hl:2,fg+:15,bg+:8,hl+:2,gutter:-1,pointer:1,info:8,spinner:8,header:8,border:8,prompt:4,marker:3'"
    ];
    changeDirWidgetCommand = "${fd "directory"} '.' ${config.home.homeDirectory}";
    fileWidgetCommand = fd "file";
  };

  programs.gh.enable = true;

  # TODO: enable commit signing
  programs.git = let
    package = pkgs.git.override { withLibsecret = true; };
  in {
    inherit package;
    enable = true;
    userName = "Ben Maddison";
    userEmail = "benm@workonline.africa";
    lfs.enable = true;
    aliases = {
      "root" = "rev-parse --show-toplevel";
    };
    extraConfig = {
      credential.helper = "${package}/bin/git-credential-libsecret";
    };
  };

  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    mutableKeys = false;
    mutableTrust = false;
  };

  programs.home-manager.enable = true;

  programs.i3status-rust = {
    enable = true;
    bars.default = {
      blocks = [
        {
          block = "memory";
          display_type = "memory";
          format_mem = "{mem_used_percents}";
          format_swap = "{swap_used_percents}";
        }
        {
          block = "cpu";
          interval = 1;
        }
        {
          block = "battery";
        }
        {
          block = "time";
          interval = 60;
          format = "%a %d/%m %R";
        }
      ];
      icons = "awesome";
      theme = "nord-dark";
    };
  };

  programs.info.enable = true;

  programs.jq.enable = true;

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
            vim.keymap.set('n', '<C-K>', vim.lsp.buf.signature_help, opts)
          end
          require('lspconfig').rnix.setup {
            cmd = { "${pkgs.rnix-lsp}/bin/rnix-lsp" },
            on_attach = on_attach,
            capabilities = capabilities,
          }
          EOF
        '';
      }
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
            sources = {
              { name = 'nvim_lsp' },
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

  programs.nix-index.enable = true;

  programs.ssh.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = lib.concatStrings [
        "$nix_shell"
        "$golang"
        "$julia"
        "$lua"
        "$nim"
        "$nodejs"
        "$purescript"
        "$python"
        "$ruby"
        "$rust"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_status"
        "$hg_branch"
        "$username"
        "$hostname"
        "$directory"
        "$jobs"
        "$character"
      ];
      character = {
        success_symbol = "[\\$](bold green)";
        error_symbol = "[\\$](bold red)";
      };
    };
  };

  programs.tealdeer.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      pane_frames = false;
      keybinds.unbind = [ { Ctrl = "h"; } ];
      theme = "nord";
      themes.nord = {
        fg = [ 216 222 233 ];
        bg = [ 46 52 64 ];
        black = [ 59 66 82 ];
        red = [ 191 97 106 ];
        green = [ 163 190 140 ];
        yellow = [ 235 203 139 ];
        blue = [ 129 161 193 ];
        magenta = [ 180 142 173 ];
        cyan = [ 136 192 208 ];
        white = [ 229 233 240 ];
        orange = [ 208 135 112 ];
      };
    };
  };
  xdg.configFile."zellij/layouts/default.yaml".text =
    lib.generators.toYAML {} {
      template = {
        direction = "Horizontal";
        parts = [
          {
            direction = "Vertical";
            split_size.Fixed = 1;
            run.plugin.location = "zellij:tab-bar";
            borderless = true;
          }
          {
            direction = "Vertical";
            body = true;
          }
          #{
          #  direction = "Vertical";
          #  split_size.Fixed = 2;
          #  run.plugin.location = "zellij:status-bar";
          #  borderless = true;
          #}
        ];
      };
      tabs = [ { direction = "Vertical"; } ];
    };

  programs.zoxide.enable = true;

  services.gnome-keyring.enable = true;
  systemd.user.paths.gnome-keyring = {
    Unit.Description = "Watch for gnome-keyring path";
    Path.PathExists = "/run/user/1000/keyring";
    Install.WantedBy = [ "paths.target" ];
  };

  services.keybase.enable = true;
  services.kbfs = {
    enable = true;
    mountPoint = "documents/keybase";
  };

  xdg = {
    enable = true;
    mimeApps.enable = true;
    userDirs = let home = config.home.homeDirectory; in {
      enable = true;
      createDirectories = true;
      desktop = "${home}/desktop";
      documents = "${home}/documents";
      download = "${home}/downloads";
      music = "${home}/media/music";
      pictures = "${home}/media/pictures";
      publicShare = "${home}/public";
      templates = "${home}/templates";
      videos = "${home}/media/videos";
    };
  };

  xsession = {
    enable = true;
    windowManager.i3 = let
      fonts = {
        names = [ "SauceCodePro Nerd Font" ];
        style = "Regular";
        size = 12.0;
      };
    in {
      enable = true;
      package = pkgs.i3-gaps;
      config = {
        inherit fonts;
        bars = [
          {
            inherit fonts;
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";
            colors = with colors; {
              background = black;
              separator = light-grey;
              statusline = light-grey;
              focusedWorkspace = {
                background = blue;
                border = light-blue;
                text = white;
              };
              activeWorkspace = {
                background = dark-grey;
                border = dark-grey;
                text = light-grey;
              };
              inactiveWorkspace = {
                background = dark-grey;
                border = dark-grey;
                text = light-grey;
              };
              urgentWorkspace = {
                background = dark-grey;
                border = red;
                text = red;
              };
              bindingMode = {
                background = dark-grey;
                border = yellow;
                text = yellow;
              };
            };
          }
        ];
        colors = {
          background = colors.black;
        };
        defaultWorkspace = "workspace number 1";
        floating.criteria = [];
        gaps.inner = 6;
        keybindings = let
          cfg = config.xsession.windowManager.i3.config;
          mod = cfg.modifier;
          alt = "Mod1";
        in {
          "${mod}+Return" = "exec ${cfg.terminal}";
          # TODO: "${mod}+Shift+Return" -> launch browser
          "${mod}+space" = "exec ${cfg.menu}";
          # TODO: "${mod}+Shift+space" -> cmd launcher
          # TODO: "${mod}+Ctrl+space" -> window launcher
          # TODO: "${mod}+${alt}+space" -> file launcher
          # TODO: "${mod}+Shift+question" -> help pop-up
          # TODO: "${mod}+equal" -> calulator
          # TODO: "${mod}+z" -> fuzzy finder
          "${mod}+q" = "[con_id=\"focused\"] kill";

          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          "${mod}+Ctrl+h" = "move workspace to output left";
          "${mod}+Ctrl+j" = "move workspace to output down";
          "${mod}+Ctrl+k" = "move workspace to output up";
          "${mod}+Ctrl+l" = "move workspace to output right";

          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";
          "${mod}+0" = "workspace number 10";
          # TODO: "${mod}+Ctrl+[0..9] -> workspaces 11 - 20

          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";
          "${mod}+Shift+0" = "move container to workspace number 10";
          # TODO: "${mod}+Shift+Ctrl+[0..9] -> workspaces 11 - 20

          "${mod}+${alt}+1" = "move container to workspace number 1; workspace number 1";
          "${mod}+${alt}+2" = "move container to workspace number 2; workspace number 2";
          "${mod}+${alt}+3" = "move container to workspace number 3; workspace number 3";
          "${mod}+${alt}+4" = "move container to workspace number 4; workspace number 4";
          "${mod}+${alt}+5" = "move container to workspace number 5; workspace number 5";
          "${mod}+${alt}+6" = "move container to workspace number 6; workspace number 6";
          "${mod}+${alt}+7" = "move container to workspace number 7; workspace number 7";
          "${mod}+${alt}+8" = "move container to workspace number 8; workspace number 8";
          "${mod}+${alt}+9" = "move container to workspace number 9; workspace number 9";
          "${mod}+${alt}+0" = "move container to workspace number 10; workspace number 10";
          # TODO: "${mod}+Shift+Ctrl+[0..9] -> workspaces 11 - 20

          "${mod}+Tab"       = "workspace next";
          "${mod}+Shift+Tab" = "workspace previous";

          # TODO: scratchpad move/show

          "${mod}+backslash" = "[urgent=oldest] focus";

          "${mod}+BackSpace" = "split toggle";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+t" = "layout toggle tabbed splith splitv";
          "${mod}+Shift+f" = "floating toggle";
          "${mod}+Shift+t" = "focus mode_toggle";

          "${mod}+Escape" = "exec systemctl start physlock.service";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+q" = "exec i3-msg exit";

          # TODO: "${mod}+grave -> show tray
          # TODO: "${mod}+Shift+v -> vpn toggle
          # TODO: "${mod}+n -> notifications
          # TODO: "${mod}+Shift+n -> file manager

          "${mod}+r" = "mode resize";
        };
        modifier = "Mod4";
        terminal = "${pkgs.alacritty}/bin/alacritty";
      };
    };
    profilePath = ".config/sx/profile";
    scriptPath = ".config/sx/sxrc";
  };
  
}
