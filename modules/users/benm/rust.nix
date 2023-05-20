{ self }: { config, pkgs, lib, system, ... }:

let
  cfg = config.local.rust;
in
{
  options.local.rust = {
    enable = lib.mkEnableOption "rust";
  };

  config = lib.mkIf (cfg.enable) {

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    };

    home.sessionPath = [ "$CARGO_HOME/bin" ];

    home.packages = with pkgs; [
      llvmPackages.clang
      rustup
    ];
  };
}
