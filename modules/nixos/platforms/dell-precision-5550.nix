{ lib, config, ... }:
let
  inherit (lib) mkOption mkIf types;
  platformName = "dell-precision-5550";
in
{
  options.platform = mkOption {
    type = types.enum [ platformName ];
  };

  config = mkIf (config.platform == platformName) {
    nixpkgs.system = "x86_64-linux";

    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      initrd = {
        availableKernelModules = [
          "xhci_pci"
          "nvme"
          "usb_storage"
          "sd_mod"
          "rtsx_pci_sdmmc"
        ];
        kernelModules = [ ];
      };
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
    };

    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
      };
    };

    swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

    powerManagement.cpuFreqGovernor = "powersave";

    hardware = {
      enableRedistributableFirmware = true;
      cpu.intel.updateMicrocode = true;
      nitrokey.enable = true;
      gpgSmartcards.enable = true;
      bluetooth.enable = true;
      acpilight.enable = true;
    };

    systemd.sleep.settings.Sleep = {
      AllowSuspend = false;
    };

    networking.networkmanager.enable = true;

    services = {
      autorandr.enable = true;

      gnome.gnome-keyring.enable = true;

      hardware.bolt.enable = true;

      keyd.enable = true;

      logind.settings.Login = {
        KillUserProcesses = true;
        HandleLidSwitch = "hibernate";
        IdleAction = "lock";
        IdleActionSec = 300;
        HandlePowerKey = "hibernate";
        HandlePowerKeyLongPress = "poweroff";
      };

      pcscd.enable = true;

      physlock = {
        enable = true;
        lockMessage = "This system is locked";
      };

      pipewire.enable = true;

      resolved.settings.Resolve.DNSSEC = true;

      xserver = {
        enable = true;
        autorun = false;
        xkb.layout = "us";
        displayManager.sx.enable = true;
      };
    };

    virtualisation.docker.enable = true;
  };
}
