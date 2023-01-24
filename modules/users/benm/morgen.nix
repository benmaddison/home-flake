{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.morgen;
in
{
  options.local.morgen = {
    enable = lib.mkEnableOption "morgen";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.morgen ];
    local.persistence.directories = [ ".config/Morgen" ];
  };
}
