{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
    let
      lib = import ./lib { inherit (inputs.nixpkgs) lib; };
      overlay = import ./pkgs/overlay.nix { };
      nixosModules = import ./modules {
        extraModules = [
          inputs.impermanence.nixosModules.impermanence
          inputs.home-manager.nixosModules.home-manager
          ({ ... }: {
            nixpkgs.overlays = [ overlay ];
            system.systemBuilderCommands = lib.systemSourceLinksCommand inputs;
          })
        ];
      };
    in
    {
      inherit lib;
      overlays.default = overlay;
      nixosConfigurations = import ./systems {
        inherit lib nixosModules;
      };
    };
}
