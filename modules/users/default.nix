{ self }: { config, options, lib, ... }:

let
  cfg = config.local.users;
in
{
  imports = [ self.inputs.home-manager.nixosModules.home-manager ];

  options = {
    local.users = lib.mkOption {
      type = with lib.types; attrsOf (submodule ({ name, ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
          hashedPassword = lib.mkOption {
            type = lib.types.str;
          };
          homeManagerConfig = lib.mkOption {
            type = with lib.types; nullOr path;
            default = ./. + "/${name}";
          };
        };
      }));
      default = { };
    };
  };

  config = lib.mkIf (cfg != { }) {
    users = {
      mutableUsers = false;
      users =
        let
          makeUser = name: user: {
            isNormalUser = true;
            extraGroups = [
              "dialout"
              "docker"
              "networkmanager"
              "wheel"
            ];
            initialHashedPassword = user.hashedPassword;
          };
        in
        lib.mapAttrs makeUser cfg;
    };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users =
        let
          enabled = _: user: user.homeManagerConfig != null;
          hmConfig = _: user: self.lib.import user.homeManagerConfig;
        in
        lib.mapAttrs hmConfig (lib.filterAttrs enabled cfg);
    };
  };
}
