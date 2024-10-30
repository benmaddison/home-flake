{ self }: { config, options, lib, pkgs, ... }:

let
  cfg = config.local.gpg;
  keyIdRegex = "^0x[[:xdigit:]]{8}$";
  keyIdOption = with lib; mkOption {
    type = with types; nullOr (strMatching keyIdRegex);
    default = null;
  };
in
{
  options.local.gpg = {
    enable = lib.mkEnableOption "enable GnuPG";
    defaultSignKey = keyIdOption;
    defaultEncryptKey = keyIdOption;
  };

  config = lib.mkIf cfg.enable {
    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      mutableKeys = false;
      mutableTrust = false;
      scdaemonSettings.disable-ccid = true;
    };
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };
}
