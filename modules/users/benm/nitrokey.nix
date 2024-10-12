{ self }: { config, pkgs, lib, ... }:
let
  cfg = config.local.nitrokey;
in
{
  options.local.nitrokey = {
    enable = lib.mkEnableOption "nitrokey";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nitrokey-app2
      opensc
      pynitrokey
    ];
  };
}
