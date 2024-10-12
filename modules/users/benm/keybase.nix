{ self }: { config, lib, pkgs, ... }:
let
  cfg = config.local.keybase;
in
{
  options.local.keybase = {
    enable = lib.mkEnableOption "enable keybase";
  };

  config = lib.mkIf cfg.enable {
    services.keybase.enable = true;
    services.kbfs = {
      enable = true;
      mountPoint = "documents/keybase";
    };
    home.packages = [ pkgs.keybase-gui ];
    local.persistence.directories = [ ".config/keybase" ];

    # Workaround https://github.com/nix-community/home-manager/issues/4722
    systemd.user.services.kbfs.Service.PrivateTmp = lib.mkForce false;
  };
}
