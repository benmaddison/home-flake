{ self }: { config, pkgs, lib, system, ... }:

let
  cfg = config.local.rust;
  extPkgs = pkgs.extend self.inputs.fenix.overlays.default;
in
{
  options.local.rust = {
    enable = lib.mkEnableOption "rust";
    toolchains = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };

  config = lib.mkIf (cfg.enable) {

    home.packages = with extPkgs; [ gcc ]
      ++ map (name: fenix.${name}.toolchain) cfg.toolchains;

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    };
  };
}
