{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... } @ inputs:
  {
    nixosConfigurations.iolcus = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./iolcus.nix ];
      specialArgs = { inherit self; };
    };
  };
}
