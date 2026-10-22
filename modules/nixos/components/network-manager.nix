{ lib, config, ... }:
let
  inherit (lib) mkIf mkForce;
  inherit (config.persistentStorage) systemPath;
in
{
  config = mkIf (config.networking.networkmanager.enable) {
    systemd.services.systemd-networkd-wait-online.enable = mkForce false;
    environment.persistence.${systemPath}.directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
