{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.vifm;
  nvimMapOpt = default: lib.mkOption {
    type = lib.types.str;
    default = default;
  };
in
{
  options.local.vifm = {
    enable = lib.mkEnableOption "enable vifm";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vifm-full;
    };
    neovimPlugin = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "enable vifm.vim plugin";
          mappings = lib.mkOption {
            type = lib.types.submodule {
              options = {
                Edit = nvimMapOpt "<leader>fe";
                Split = nvimMapOpt "<leader>fs";
                Vsplit = nvimMapOpt "<leader>fv";
                Tab = nvimMapOpt "<leader>ft";
                Diff = nvimMapOpt "<leader>fd";
              };
            };
            default = { };
          };
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
          };
        };
      };
      default = { };
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        options =
          let
            opt = type: default: lib.mkOption {
              inherit default;
              type = lib.types.nullOr type;
            };
          in
          {
            options = lib.mkOption {
              type = lib.types.submodule {
                freeformType = with lib.types;
                  attrsOf (enum [ bool int str ]);
                options = with lib.types; {
                  vicmd = opt str "vim";
                  syscalls = opt bool true;
                  trash = opt bool true;
                  history = opt int 100;
                  vifminfo = opt str
                    "dhistory,savedirs,chistory,state,tui,shistory,phistory,fhistory,dirstack,registers,bookmarks,bmarks";
                  followlinks = opt bool false;
                  sortnumbers = opt bool true;
                  undolevels = opt int 100;
                  vimhelp = opt bool true;
                  runexec = opt bool false;
                  timefmt = opt str "'%Y/%m/%d %H:%M'";
                  wildmenu = opt bool true;
                  wildstyle = opt str "popup";
                  ignorecase = opt bool true;
                  smartcase = opt bool true;
                  hlsearch = opt bool false;
                  incsearch = opt bool true;
                  scrolloff = opt int 4;
                  slowfs = opt str "curlftpfs";
                  statusline = opt str "'  Hint: %z%= %A %10u:%-7g %15s %20d  '";
                };
              };
              default = { };
            };
            colorscheme = lib.mkOption {
              type = with lib.types; nullOr str;
              default = "Default-256 Default";
            };
            marks = lib.mkOption {
              type = with lib.types; attrsOf str;
              default = {
                h = "~/";
                b = "~/bin/";
              };
            };
            commands = lib.mkOption {
              type = with lib.types; attrsOf (submodule {
                options = {
                  overwrite = lib.mkOption {
                    type = bool;
                    default = true;
                  };
                  action = lib.mkOption {
                    type = str;
                  };
                  background = lib.mkOption {
                    type = bool;
                    default = false;
                  };
                };
              });
              default = {
                df.action = "df -h %m 2> /dev/null";
                diff.action = "vim -d %f %F";
                zip.action = "zip -r %c.zip %f";
                run.action = "!! ./%f";
                make.action = "!!make %a";
                mkcd.action = ":mkdir %a | cd %a";
                vgrep.action = "vim \"+grep %a\"";
                reload.action = ":write | restart full";
              };
            };
          };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.neovim.plugins = lib.mkIf cfg.neovimPlugin.enable [{
      plugin = pkgs.vimPlugins.vifm-vim;
      config = with lib; self.lib.code "vim" ''
        lua <<EOF
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        vim.g.vifm_replace_netrw = 1

        ${concatStrings (mapAttrsToList (cmd: keys: ''
          vim.keymap.set('n', '${keys}', '<cmd>${cmd}Vifm<cr>', {})
        '') cfg.neovimPlugin.mappings)}

        ${cfg.neovimPlugin.extraConfig}
        EOF
      '';
    }];

    xdg.configFile."vifm/vifmrc".text =
      let
        concatMapSettings = with lib; f: s: concatStrings (mapAttrsToList f s);
        setOpt = with lib.types; opt: val:
          if val != null then
            if val == true then ''
              set ${opt}
            '' else if val == false then ''
              set no${opt}
            '' else ''
              set ${opt}=${toString val}
            ''
          else "";
        setMark = key: dir: ''
          mark ${key} ${dir}
        '';
        setCommand = name: cmd:
          let
            bang = if cmd.overwrite then "!" else "";
            bg = if cmd.background then " &" else "";
          in
          ''
            command${bang} ${name} ${cmd.action}${bg}
          '';
      in
      with lib; with cfg.settings; self.lib.code "vifm" ''
        ${concatMapSettings setOpt options}

        ${if colorscheme == null then "" else ''
          colorscheme ${colorscheme}
        ''}

        ${concatMapSettings setMark marks}

        ${concatMapSettings setCommand commands}
      '';
  };
}
