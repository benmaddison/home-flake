{ self }:

let

  systems = {
    iolcus.system = "x86_64-linux";
  };

  makeSystems = let
    lib = self.inputs.nixpkgs.lib;
    makeSystem = name: sys: lib.nixosSystem {
      inherit (sys) system;
      modules = [ (./. + "/${name}.nix") ];
      specialArgs = { inherit self; };
    };
  in systems: builtins.mapAttrs makeSystem systems;

in makeSystems systems
