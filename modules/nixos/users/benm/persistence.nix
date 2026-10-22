{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.local.persistence;
in
{
  options.local.persistence = {
    enable = mkEnableOption "persistence";
    path = mkOption {
      type = types.str;
      default = "/data/user";
    };
    files = mkOption {
      type = with types; listOf str;
    };
    directories = mkOption {
      type = with types; listOf str;
    };
  };

  config = mkIf (cfg.enable) {
    home.persistence.${cfg.path} = {
      inherit (cfg) files directories;
    };
  };
}
