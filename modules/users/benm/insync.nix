{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.insync;
in
{
  options.local.insync = {
    enable = lib.mkEnableOption "insync";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.insync-v3 ];
    local.persistence.directories = [ ".config/Insync" ];
  };
}
