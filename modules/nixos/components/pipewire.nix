{ lib, config, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.services.pipewire.enable) {
    security.rtkit.enable = true;
    services.pipewire = {
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };
}
