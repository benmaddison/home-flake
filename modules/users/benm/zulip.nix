{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.zulip;
in
{
  options.local.zulip = {
    enable = lib.mkEnableOption "zulip";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.zulip ];
    local.persistence.directories = [ ".config/Zulip" ];
  };
}
