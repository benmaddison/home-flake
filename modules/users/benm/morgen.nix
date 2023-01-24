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
    home.persistence."/data/user/benm".directories = [ ".config/Morgen" ];
  };
}
