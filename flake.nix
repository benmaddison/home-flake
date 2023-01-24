{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
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
      let pkgs = inputs.nixpkgs.legacyPackages.${system}; in

      rec {
        packages = {
          oauth2ms = pkgs.callPackage ./pkgs/oauth2ms.nix { };
          cyrus-sasl-xoauth2 = pkgs.callPackage ./pkgs/cyrus-sasl-xoauth2.nix { };
        };
      }
    );
}
