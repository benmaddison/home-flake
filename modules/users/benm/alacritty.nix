{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.alacritty;
  exec-path = "${cfg.package}/bin/alacritty";
in
{
  options.local.alacritty = {
    enable = lib.mkEnableOption "alacritty terminal";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.alacritty;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      inherit (cfg) enable package;
      settings = {
        colors = with config.local.colorscheme.hashHex; {
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
          size = 8;
        };
      };
    };

    programs.rofi.terminal = exec-path;

    xsession.windowManager.i3.config.terminal = exec-path;
  };
}
