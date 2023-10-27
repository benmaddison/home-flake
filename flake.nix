{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... } @ inputs:
    {
      lib = import ./lib { inherit self; };

      nixosConfigurations = self.lib.import ./systems;

      nixosModules = self.lib.import ./modules;
    }

    // inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        callPackage = path: pkgs.callPackage path { inherit self; };
      in

      rec {
        packages = {
          oauth2ms = callPackage ./pkgs/oauth2ms.nix;
          cyrus-sasl-xoauth2 = callPackage ./pkgs/cyrus-sasl-xoauth2.nix;
          nord-rofi-theme = callPackage ./pkgs/nord-rofi-theme.nix;
        };
      }
    );
}
