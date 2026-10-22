{ lib, config, ... }:
let
  inherit (lib) mkIf;
  inherit (config.persistentStorage) systemPath;
in
{
  config = mkIf (config.hardware.bluetooth.enable) {
    services.blueman.enable = true;

    environment.persistence.${systemPath}.directories = [
      "/var/lib/bluetooth"
    ];
  };
}
