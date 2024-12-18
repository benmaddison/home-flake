{ self, config, pkgs, lib, modulesPath, ... }:

let
  unfreePkgs = [ "morgen" "zoom" "slack" "pypemicro" ];
  insecurePkgs = [ "electron-25.9.0" ];
in
{
  imports = with self.inputs; [
    (modulesPath + "/installer/scan/not-detected.nix")
    impermanence.nixosModules.impermanence
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    packages = with pkgs; [ terminus_font powerline-fonts ];
    font = "ter-powerline-v16n";
    colors = with self.lib.colors "nord" "hex"; [
      primary.background
      normal.red
      normal.green
      normal.yellow
      normal.blue
      normal.magenta
      normal.cyan
      primary.foreground
    ] ++ (lib.attrValues bright);
  };
  services.kmscon = {
    # enable = true;
    fonts = [
      { name = "Source Code Pro"; package = pkgs.source-code-pro; }
    ];
    hwRender = true;
    extraConfig = ''
      palette = base16-dark
    '';
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "size=8G" "mode=755" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/disk/by-label/nix";
      fsType = "ext4";
    };
    "/data/system" = {
      device = "/dev/disk/by-label/system-data";
      fsType = "ext4";
      neededForBoot = true;
    };
    "/data/user" = {
      device = "/dev/disk/by-label/user-data";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

  powerManagement.cpuFreqGovernor = "powersave";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  services.hardware.bolt.enable = true;

  services.pcscd.enable = true;
  hardware.nitrokey.enable = true;
  hardware.gpgSmartcards.enable = true;

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
  '';

  services.logind = {
    killUserProcesses = true;
    lidSwitch = "hibernate";
    extraConfig = ''
      IdleAction=lock
      IdleActionSec=300
      HandlePowerKey=hibernate
      HandlePowerKeyLongPress=poweroff
    '';
  };

  services.physlock = {
    enable = true;
    lockMessage = "This system is locked";
  };

  networking.hostName = "iolcus";
  networking.useNetworkd = true;
  networking.networkmanager.enable = true;
  networking.search = [ "wolcomm.net" ];
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  networking.firewall = {
    checkReversePath = false;
    logRefusedPackets = true;
    logRefusedUnicastsOnly = true;
  };
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  services.resolved.dnssec = "true";

  local.users.benm.hashedPassword = "$6$Fjct9SMOV8uWIMrU$vTqfSYHFk/dgAyy0UTq/notTPcfmZiGpW9t3lVFmbB8aZnkDu5/0kJs8W5a3Uc1Edzh0mReXgk/iKdR3mPm8Z1";

  services.gnome.gnome-keyring.enable = true;

  services.dbus.packages = [ pkgs.gcr ];

  services.xserver = {
    enable = true;
    autorun = false;
    xkb.layout = "us";
    displayManager.sx.enable = true;
    # TODO:
    #xkbOptions = {};
  };
  services.libinput.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.autorandr.enable = true;

  environment.systemPackages = with pkgs; [
    pciutils
    sedutil
    wget
  ];

  environment.persistence."/data/system" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/boltd"
      "/var/lib/nixos"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  system.extraSystemBuilderCmds = ''
    mkdir -p $out/source/inputs
    ln -s ${self} $out/source/self
    ${lib.concatStrings (
      lib.mapAttrsToList (name: source: ''
        ln -s ${source} $out/source/inputs/${name}
      '')
      self.inputs
    )}
  '';

  nix = {
    settings = {
      trusted-users = [ "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };
    nixPath = [ "nixpkgs=/run/current-system/source/inputs/nixpkgs" ];
    registry =
      lib.mapAttrs (name: flake: { inherit flake; }) self.inputs //
      {
        system.to = {
          type = "github";
          owner = "benmaddison";
          repo = "home-flake";
        };
        slides-template.to = {
          type = "github";
          owner = "benmaddison";
          repo = "slides-template";
        };
      };
  };
  nixpkgs.config =
    {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePkgs;
      permittedInsecurePackages = insecurePkgs;
    };

  programs.dconf.enable = true;

  programs.fuse.userAllowOther = true;

  programs.light.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  virtualisation.docker.enable = true;

  system.stateVersion = "22.05";

}
