{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.local.firefox;
in
{
  options.local.firefox = {
    enable = mkEnableOption "enable firefox";
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles.default = { };
      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };
    local.persistence.directories = [ ".config/mozilla/firefox" ];
  };
}
