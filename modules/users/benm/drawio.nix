{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.drawio;
in
{
  options.local.drawio = {
    enable = lib.mkEnableOption "draw.io";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.drawio;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    local.persistence.directories = [ ".config/draw.io" ];
  };
}
