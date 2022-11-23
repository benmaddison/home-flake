{ self }:

let

  systems = {
    iolcus.system = "x86_64-linux";
  };

  makeSystems = let
    lib = self.inputs.nixpkgs.lib;
    modules = name:
      [ (./. + "/${name}.nix") ]
      ++ builtins.attrValues self.nixosModules;
    makeSystem = name: sys: lib.nixosSystem {
      inherit (sys) system;
      modules = modules name;
      specialArgs = { inherit self; };
    };
  in systems: builtins.mapAttrs makeSystem systems;

in makeSystems systems
