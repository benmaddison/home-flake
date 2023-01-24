{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.azure;
in
{
  options.local.azure = {
    enable = lib.mkEnableOption "azure-cli";
    package = lib.mkPackageOption pkgs "azure-cli" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = {
      AZURE_CONFIG_DIR = "${config.xdg.dataHome}/azure";
    };
  };
}
