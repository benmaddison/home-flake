{ lib, config, ... }:
let
  inherit (lib) mkIf;
  inherit (config.persistentStorage) systemPath;
in
{
  config = mkIf (config.services.hardware.bolt.enable) {

    environment.persistence.${systemPath}.directories = [
      "/var/lib/boltd"
    ];
  };
}
