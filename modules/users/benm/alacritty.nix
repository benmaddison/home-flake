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
    # work around broken per-monitor DPI scaling
    home.sessionVariables.WINIT_X11_SCALE_FACTOR = 1;

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
      };
    };

    programs.rofi.terminal = exec-path;

    xsession.windowManager.i3.config.terminal = exec-path;
  };
}
