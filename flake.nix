{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs =
    { self, ... }@inputs:
    {
      lib = import ./lib { inherit self; };

      nixosConfigurations = self.lib.import ./systems;

      nixosModules = self.lib.import ./modules;
    }

    // inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        callPackage = path: pkgs.callPackage path { inherit self; };
      in

      {
        packages = {
          oauth2ms = callPackage ./pkgs/oauth2ms.nix;
          cyrus-sasl-xoauth2 = callPackage ./pkgs/cyrus-sasl-xoauth2.nix;
          nord-rofi-theme = callPackage ./pkgs/nord-rofi-theme.nix;
        };
      }
    );
}
