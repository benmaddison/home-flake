{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.slack;
in
{
  options.local.slack = {
    enable = lib.mkEnableOption "slack";
  };

  config = lib.mkIf (cfg.enable) {
    home.packages = [ pkgs.slack ];
    local.persistence.directories = [ ".config/Slack" ];
  };
}
