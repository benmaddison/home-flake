{ self }: { config, options, lib, ... }:

let
  cfg = config.local.persistence;
in
{
  imports = [
    self.inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  options.local.persistence =
    let
      persistOpts = options.home.persistence.type.getSubOptions [ ];
      wrap = name: args: self.lib.wrapOption persistOpts.${name} args;
    in
    {
      enable = lib.mkEnableOption "persistence";
      path = lib.mkOption {
        type = lib.types.str;
        default = "/data/user/${config.home.username}";
      };
      allowOther = wrap "allowOther" { default = true; };
      files = wrap "files" { };
      directories = wrap "directories" { };
    };

  config = lib.mkIf (cfg.enable) {
    home.persistence.${cfg.path} = {
      inherit (cfg) allowOther files directories;
    };
  };
}
