{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.rofi;
  system = pkgs.system;
in
{
  options.local.rofi = {
    enable = lib.mkEnableOption "rofi";
  };

  config = lib.mkIf (cfg.enable) {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
      theme = "${self.packages.${system}.nord-rofi-theme}/nord.rasi";
    };

    xsession.windowManager.i3.config.keybindings =
      let
        mod = config.xsession.windowManager.i3.config.modifier;
        rofi-pulse-select =
          type: "${pkgs.rofi-pulse-select}/bin/rofi-pulse-select ${type}";
      in
      {
        "${mod}+s" = "exec ${rofi-pulse-select "sink"}";
        "${mod}+Shift+s" = "exec ${rofi-pulse-select "source"}";
      };
  };
}
