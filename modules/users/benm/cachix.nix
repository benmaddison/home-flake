{ self }: { config, lib, pkgs, ... }:
let
  name = "cachix";
  cfg = config.local.cachix;
in
{
  options.local.cachix = {
    enable = lib.mkEnableOption name;
    package = lib.mkPackageOption pkgs name {};
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    local.persistence.directories = [ ".config/cachix" ];
  };
}
