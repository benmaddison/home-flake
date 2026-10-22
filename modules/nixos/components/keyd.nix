{ lib, config, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.services.keyd.enable) {

    services = {
      libinput.enable = true;

      keyd.keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            d = "lettermod(nav, d, 150, 200)";
          };
          nav = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            f = "lettermod(nav-page, f, 150, 200)";
          };
          nav-page = {
            j = "pagedown";
            k = "pageup";
          };
        };
      };
    };
  };
}
