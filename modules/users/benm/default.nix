{ self }: { config, pkgs, lib, ... }:

let
  colors = self.lib.colors "nord" "hashHex";
  neovim = self.lib.import ./neovim.nix;
  mail = self.lib.import ./mail.nix;
  gpg = self.lib.import ./gpg.nix;
  rust = self.lib.import ./rust.nix;
in {
  home.username = "benm";
  home.homeDirectory = "/home/benm";
  home.stateVersion = "22.05";

  imports = [
    self.inputs.impermanence.nixosModules.home-manager.impermanence
    neovim mail gpg rust
  ];

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
      ".zoom"
    ];
  };

  home.packages = with pkgs; [
    du-dust
    fd
    libreoffice
    libsecret
    nerdfonts
    nix-diff
    ripgrep
    w3m
    zoom-us
  ];

  fonts.fontconfig.enable = true;

  local = {
    gpg = {
      enable = true;
      defaultSignKey = "0xB48B6860";
      defaultEncryptKey = "0xFEA8F45D";
    };
    mail = {
      workonline = {
        address = "benm@workonline.africa";
        aliases = [
          "benm@workonline.co.za"
          "ben@workonline.co.za"
          "benmaddison@workonline.co.za"
          "maddison@workonline.co.za"
          "benjmaddison@workonline.co.za"
        ];
        primary = true;
        imap.host = "outlook.office365.com";
        smtp = {
          host = "smtp.office365.com";
          port = 587;
          tls.useStartTls = true;
        };
        folders = {
          inbox = "INBOX";
          sent = "Sent Items";
          trash = "Deleted Items";
        };
        extraFolders.spam = "Junk Email";
        mbsyncPipelineDepth = 1;
      };
      family = {
        address = "ben@maddison.family";
        aliases = [ "bm@mycenae.holdings" ];
        flavor = "fastmail.com";
        folders.inbox = "INBOX";
        extraFolders.snoozed = "Snoozed";
      };
    };
    neovim.enable = true;
    rust.toolchains = [ "stable" ];
  };

  programs.alacritty = {
    enable = true;
    settings = {
      colors = with colors; {
        inherit primary normal bright dim;
        search.matches = {
            background = normal.cyan;
            foreground = "CellBackground";
        };
        footer_bar = {
          background = misc.nord2;
          foreground = misc.nord4;
        };
      };
      font = {
        normal.family = "SauceCodePro Nerd Font Mono";
        size = 10;
      };
    };
  };

  programs.autorandr = {
    enable = true;
    profiles = {
      mobile = {
        fingerprint = {
          eDP-1 = "00ffffffffffff004d10d11400000000041e0104a52215780ede50a3544c99260f505400000001010101010101010101010101010101283c80a070b023403020360050d210000018203080a070b023403020360050d210000018000000fe00464b52314b804c513135364e31000000000002410332001200000a010a2020003a";
        };
        config = {
          eDP-1 = {
            enable = true;
            crtc = 0;
            primary = true;
            position = "0x0";
            mode = "1920x1200";
            rate = "60.00";
          };
        };
      };
      office = {
        fingerprint = {
          DP-1-1 = "00ffffffffffff0010aca7a04c395430171e0104a55021783afd25a2584f9f260d5054a54b00714f81008180a940d1c0010101010101e77c70a0d0a029505020ca041e4f3100001a000000ff0046315431573036333054394c0a000000fc0044454c4c205533343135570a20000000fd0030551e5920000a2020202020200151020319f14c9005040302071601141f12132309070783010000023a801871382d40582c25001e4f3100001e584d00b8a1381440942cb5001e4f3100001e9d6770a0d0a0225050205a041e4f3100001a3c41b8a060a029505020ca041e4f3100001a565e00a0a0a02950302035001e4f3100001a000000000000000000000000bf";
          DP-1-2 = "00ffffffffffff0010aca7a04c415430171e0104a55021783afd25a2584f9f260d5054a54b00714f81008180a940d1c0010101010101e77c70a0d0a029505020ca041e4f3100001a000000ff0046315431573036333054414c0a000000fc0044454c4c205533343135570a20000000fd0030551e5920000a2020202020200141020319f14c9005040302071601141f12132309070783010000023a801871382d40582c25001e4f3100001e584d00b8a1381440942cb5001e4f3100001e9d6770a0d0a0225050205a041e4f3100001a3c41b8a060a029505020ca041e4f3100001a565e00a0a0a02950302035001e4f3100001a000000000000000000000000bf";
          DP-1-3 = "00ffffffffffff0010acaaa04c425430171e010380502178eafd25a2584f9f260d5054a54b00714f81008180a940d1c0010101010101e77c70a0d0a029505020ca041e4f3100001a000000ff0046315431573036333054424c0a000000fc0044454c4c205533343135570a20000000fd0030551e5920000a20202020202001b2020322f14d9005040302071601141f12135a2309070767030c0020001844830100009d6770a0d0a0225050205a041e4f3100001a9f3d70a0d0a0155050208a001e4f3100001a584d00b8a1381440942cb5001e4f3100001e3c41b8a060a029505020ca041e4f3100001a565e00a0a0a02950302035001e4f3100001a00000045";
        };
        config = {
          eDP-1.enable = false;
          DP-1-1 = {
            enable = true;
            crtc = 1;
            primary = true;
            position = "3440x0";
            mode = "3440x1440";
            rate = "49.99";
          };
          DP-1-2 = {
            enable = true;
            crtc = 0;
            position = "6880x0";
            mode = "3440x1440";
            rate = "49.99";
          };
          DP-1-3 = {
            enable = true;
            crtc = 2;
            position = "0x0";
            mode = "3440x1440";
            rate = "29.99";
          };
        };
      };
    };
  };

  programs.bash = {
    enable = true;
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
    # TODO: don't assume that we're uid 1000
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
              inherit (primary) background;
              separator = bright.black;
              statusline = bright.black;
              focusedWorkspace = {
                background = normal.blue;
                border = bright.blue;
                text = bright.white;
              };
              activeWorkspace = with bright; {
                background = black;
                border = black;
                text = white;
              };
              inactiveWorkspace = with normal; {
                background = black;
                border = black;
                text = white;
              };
              urgentWorkspace = with bright; {
                background = black;
                border = red;
                text = red;
              };
              bindingMode = with bright; {
                background = black;
                border = yellow;
                text = yellow;
              };
            };
          }
        ];
        colors = with colors; { inherit (primary) background; };
        defaultWorkspace = "workspace number 1";
        floating.criteria = [];
        gaps.inner = 6;
        modifier = "Mod4";
        terminal = "${pkgs.alacritty}/bin/alacritty";
        startup = [
          {
            command = "${pkgs.networkmanagerapplet}/bin/nm-applet";
            notification = false;
          }
        ];
        keybindings = let
          cfg = config.xsession.windowManager.i3.config;
          mod = cfg.modifier;
          alt = "Mod1";

          # TODO: "Ctrl+[0..9] -> workspaces 11 - 20
          workspaces = [ 1 2 3 4 5 6 7 8 9 10 ];
          workspaceBindings = mod: cmd: let
            key = ws: toString (lib.mod ws 10);
            binding = mod: cmd: ws:
              lib.nameValuePair "${mod}+${key ws}" "${cmd ws}";
          in lib.listToAttrs (map (binding mod cmd) workspaces);
          workspaceNum = ws: "workspace number ${toString ws}";

          directions =
            { "h" = "left"; "j" = "down"; "k" = "up"; "l" = "right"; };
          navBindings = mod: cmd: let
            binding = mod: cmd: key: direction:
              lib.nameValuePair "${mod}+${key}" "${cmd direction}";
          in lib.mapAttrs' (binding mod cmd) directions;

          focusWorkspace = workspaceNum;
          moveContainerToWorkspace = ws:
            "move container to ${workspaceNum ws}";
          followContainerToWorkspace = ws:
            "${moveContainerToWorkspace ws}; ${focusWorkspace ws}";
          moveFocus = direction: "focus ${direction}";
          moveContainer = direction: "move ${direction}";
          moveWorkspaceToOutput = direction:
            "move workspace to output ${direction}";
        in
          workspaceBindings "${mod}" focusWorkspace //
          workspaceBindings "${mod}+Shift" moveContainerToWorkspace //
          workspaceBindings "${mod}+${alt}" followContainerToWorkspace //
          navBindings "${mod}" moveFocus //
          navBindings "${mod}+Shift" moveContainer //
          navBindings "${mod}+Ctrl" moveWorkspaceToOutput //
        {
          "${mod}+Return" = "exec ${cfg.terminal}";
          # TODO: "${mod}+Shift+Return" -> launch browser
          "${mod}+space" = "exec ${cfg.menu}";
          # TODO: "${mod}+Shift+space" -> cmd launcher
          # TODO: "${mod}+Ctrl+space" -> window launcher
          # TODO: "${mod}+${alt}+space" -> file launcher
          # TODO: "${mod}+Shift+question" -> help pop-up
          # TODO: "${mod}+equal" -> calulator
          # TODO: "${mod}+z" -> fuzzy finder
          "${mod}+q" = "[con_id=\"__focused__\"] kill";

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
      };
    };
    profilePath = ".config/sx/profile";
    profileExtra = ''
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
    '';
    scriptPath = ".config/sx/sxrc";
  };
  
}
