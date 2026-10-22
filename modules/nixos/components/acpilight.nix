{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  backlight = args: /* bash */ "${pkgs.acpilight}/bin/xbacklight -ctrl intel_backlight -fps 60 ${args}";
in
{
  config = mkIf (config.hardware.acpilight.enable) {
    services.keyd.keyboards.default.settings.main = {
      brightnessdown = "command(${backlight "-dec 10"})";
      brightnessup = "command(${backlight "-inc 10"})";
    };
    systemd.services.keyd.serviceConfig = {
      ReadWritePaths = [ "/sys/class/backlight/intel_backlight/" ];
    };
  };
}
