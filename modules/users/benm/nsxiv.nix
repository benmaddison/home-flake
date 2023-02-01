{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.nsxiv;
in
{
  options.local.nsxiv = {
    enable = lib.mkEnableOption "nsxiv";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nsxiv;
    };
    defaultViewer = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        options =
          let
            colorOption = lib.mkOption {
              type = with lib.types; nullOr (strMatching "^#[[:xdigit:]]{6}$");
              default = null;
            };
            background = colorOption;
            foreground = colorOption;

            font = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
            };

            section = options: lib.mkOption {
              type = lib.types.submodule {
                inherit options;
              };
              default = { };
            };

          in
          {
            window = section { inherit background foreground; };
            bar = section { inherit background foreground font; };
            mark = section { inherit foreground; };
          };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.mimeApps.defaultApplications = lib.mkIf cfg.defaultViewer {
      "image/*" = "nsxiv.desktop";
    };

    xresources.properties = self.lib.filterFlatten [ "Nsxiv" ] cfg.settings;
  };
}
