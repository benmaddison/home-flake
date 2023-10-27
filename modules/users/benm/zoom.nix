{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.zoom;
in
{
  options.local.zoom = {
    enable = lib.mkEnableOption "zoom";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zoom-us;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    local.persistence = {
      files = [
        ".config/zoom.conf"
        ".config/zoomus.conf"
        ".config/Unknown Organization/zoom.conf"
      ];
      directories = [ ".zoom" ];
    };
  };
}
