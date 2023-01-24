{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.gnome-keyring;
in
{
  options.local.gnome-keyring = {
    enable = lib.mkEnableOption "gnome-keyring";
  };

  config = lib.mkIf (cfg.enable) {
    home.packages = with pkgs; [
      libsecret
      gnome.seahorse
    ];

    services.gnome-keyring.enable = true;

    systemd.user.paths.gnome-keyring = {
      Unit.Description = "Watch for gnome-keyring path";
      # TODO: don't assume that we're uid 1000
      Path.PathExists = "/run/user/1000/keyring";
      Install.WantedBy = [ "paths.target" ];
    };

  };
}
