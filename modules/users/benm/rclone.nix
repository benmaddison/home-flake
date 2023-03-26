{ self }: { config, pkgs, lib, ... }:

let
  cfg = config.local.rclone;
  configPath = "${config.xdg.configHome}/rclone/rclone.conf";
  rclone-passwd = pkgs.writeShellScriptBin "rclone-passwd" (self.lib.code "bash" ''
    set -euo pipefail

    secret_tool="${pkgs.libsecret}/bin/secret-tool"
    av_pairs="program rclone path ${configPath}"

    help() {
      echo "usage:"
      echo "$0 <sub-command>"
      echo ""
      echo "sub-commands:"
      echo "  store: store a new file encryption password in system keyring"
      echo "  fetch: retrieve existing file encryption password from keyring"
    }

    fail() {
      echo "error: $1"
      help && exit 1
    }

    case "$1" in
      'store')
        $secret_tool store --label='rclone.conf' $av_pairs;;
      'fetch')
        $secret_tool lookup $av_pairs;;
      *)
        fail "unknown sub-command";;
    esac
  '');
  rcloneWrapped = pkgs.rclone.overrideAttrs (out: {
    postFixup = self.lib.code "bash" ''
      wrapProgram $out/bin/rclone \
        --run 'export RCLONE_CONFIG_PASS="$(${rclone-passwd}/bin/rclone-passwd fetch)"'
    '';
  });
in
{
  options.local.rclone = {
    enable = lib.mkEnableOption "rclone";
    package = lib.mkOption {
      type = lib.types.package;
      default = rcloneWrapped;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package rclone-passwd ];
    local.persistence.directories = [ ".config/rclone" ];
  };
}
