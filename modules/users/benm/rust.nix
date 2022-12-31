{ self }: { config, pkgs, lib, system, ... }:

let
  cfg = config.local.rust;
  extPkgs = pkgs.extend self.inputs.fenix.overlays.default;
in {
  options.local.rust = {
    toolchains = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
    };
  };

  config = lib.mkIf (cfg.toolchains != []) {
    home.packages = with extPkgs; [ gcc ]
      ++ map (name: fenix.${name}.toolchain) cfg.toolchains;
  };
}
