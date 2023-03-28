{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.fonts;
in
{
  options.local.fonts = {
    enable = lib.mkEnableOption "default font";
    packages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ pkgs.nerdfonts ];
    };
    family = lib.mkOption {
      type = lib.types.str;
    };
    size = lib.mkOption {
      type = lib.types.numbers.positive;
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = cfg.packages;

    programs =
      let pangoSpec = with cfg; "${family} Regular ${toString size}";
      in
      {
        alacritty.settings.font = {
          normal.family = cfg.family;
          inherit (cfg) size;
        };
        rofi.font = pangoSpec;
        zathura.options.font = pangoSpec;
      };

    xsession.windowManager.i3.config.fonts = {
      names = [ cfg.family ];
      style = "Regular";
      inherit (cfg) size;
    };
  };
}
