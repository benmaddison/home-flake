{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options = {
    platform = mkOption {
      type = types.enum [ ];
    };

    persistentStorage = {
      systemPath = mkOption {
        type = types.path;
        default = "/data/system";
        readOnly = true;
      };
      userPath = mkOption {
        type = types.path;
        default = "/data/user";
        readOnly = true;
      };
    };
  };

  config = {
    i18n.defaultLocale = "en_US.UTF-8";

    fileSystems = {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "size=8G"
          "mode=755"
        ];
      };
      "/nix" = {
        device = "/dev/disk/by-label/nix";
        fsType = "ext4";
      };
      "${config.persistentStorage.systemPath}" = {
        device = "/dev/disk/by-label/system-data";
        fsType = "ext4";
        neededForBoot = true;
      };
      "${config.persistentStorage.userPath}" = {
        device = "/dev/disk/by-label/user-data";
        fsType = "ext4";
        neededForBoot = true;
      };
    };

    console = {
      packages = with pkgs; [
        terminus_font
        powerline-fonts
      ];
      font = "ter-powerline-v16n";
      colors =
        with lib.colors "nord" "hex";
        [
          primary.background
          normal.red
          normal.green
          normal.yellow
          normal.blue
          normal.magenta
          normal.cyan
          primary.foreground
        ]
        ++ (lib.attrValues bright);
    };

    networking = {
      useNetworkd = true;
      search = [ "wolcomm.net" ];
      nameservers = [
        "1.1.1.1"
        "9.9.9.9"
      ];
      firewall = {
        checkReversePath = false;
        logRefusedPackets = true;
        logRefusedUnicastsOnly = true;
      };
    };

    nix = {
      settings = {
        trusted-users = [ "@wheel" ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      nixPath = [ "nixpkgs=/run/current-system/source/inputs/nixpkgs" ];
    };
    nixpkgs.config = {
      allowUnfreePredicate =
        pkg:
        lib.elem (lib.getName pkg) [
          "morgen"
          "zoom"
          "slack"
          "pypemicro"
          "pears.nvim"
        ];
      permittedInsecurePackages = [ ];
    };

    environment = {
      persistence.${config.persistentStorage.systemPath} = {
        directories = [
          "/var/lib/nixos"
          "/var/log"
        ];
        files = [
          "/etc/machine-id"
        ];
      };

      systemPackages = with pkgs; [
        pciutils
        sedutil
        wget
      ];
    };

    programs = {
      fuse.userAllowOther = true;
      dconf.enable = true;
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };

    security.polkit.enable = true;

    system.stateVersion = "22.05";

  };
}
