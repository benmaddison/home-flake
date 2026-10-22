{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.services.gnome.gnome-keyring.enable) {
    services.dbus.packages = [ pkgs.gcr ];
  };
}
