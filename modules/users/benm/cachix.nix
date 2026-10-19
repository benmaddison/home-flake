{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mapAttrsToList
    mkIf
    mkOption
    mkPackageOption
    mkEnableOption
    types
    ;
  name = "cachix";
  cfg = config.local.cachix;
in
{
  options.local.cachix = {
    enable = mkEnableOption name;
    package = mkPackageOption pkgs name { };
    use = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            options = {
              url = mkOption {
                type = types.str;
                default = "https://${name}.cachix.org";
              };
              public-key = mkOption {
                type = types.str;
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    nix.settings = {
      netrc-file = "${config.xdg.configHome}/nix/netrc";
      extra-substituters = mapAttrsToList (_: cache: cache.url) cfg.use;
      extra-trusted-public-keys = mapAttrsToList (_: cache: cache.public-key) cfg.use;
    };
    local.persistence = {
      files = [ ".config/nix/netrc" ];
      directories = [ ".config/cachix" ];
    };
  };
}
