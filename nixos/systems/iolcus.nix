{ self, config, pkgs, modulesPath, ... }:

{
  imports = with self.inputs; [
    (modulesPath + "/installer/scan/not-detected.nix")
    impermanence.nixosModules.impermanence
    home-manager.nixosModules.home-manager
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
    font = "ter-powerline-v20n";
    colors = [
      "2e3440" # black
      "bf616a" # red
      "a3be8c" # green
      "d08770" # orange
      "5e81ac" # blue
      "b48ead" # magenta
      "88c0d0" # cyan
      "d8dee9" # light grey
      "4c566a" # dark grey
      "bf616a" # light red
      "a3be8c" # light green
      "ebcb8b" # yellow
      "81a1c1" # light blue
      "b48ead" # light purple
      "8fbcbb" # teal
      "eceff4" # white
    ];
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

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  powerManagement.cpuFreqGovernor = "powersave";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  services.hardware.bolt.enable = true;

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
  systemd.services.systemd-networkd-wait-online.enable = false;
  services.resolved.dnssec = "true";

  time.timeZone = "Africa/Johannesburg";

  users.mutableUsers = false;
  users.users.benm = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "$6$Fjct9SMOV8uWIMrU$vTqfSYHFk/dgAyy0UTq/notTPcfmZiGpW9t3lVFmbB8aZnkDu5/0kJs8W5a3Uc1Edzh0mReXgk/iKdR3mPm8Z1";
  };

  services.gnome.gnome-keyring.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit (self.inputs.impermanence.nixosModules.home-manager) impermanence; };
    users.benm = import ./../../home-manager/users/benm.nix;
  };

  services.xserver = {
    enable = true;
    autorun = false;
    layout = "us";
    libinput.enable = true;
    displayManager.sx.enable = true;
  };

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    sedutil
    wget
  ];

  environment.persistence."/data/system" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/boltd"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    trustedUsers = [ "@wheel" ];
    registry = {
      nixpkgs.flake = self.inputs.nixpkgs;
      system.to = {
        type = "github";
        owner = "benmaddison";
        repo = "home-flake";
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  
  programs.fuse.userAllowOther = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
