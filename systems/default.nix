{
  lib,
  nixosModules,
}:
let
  systems = [
    ./iolcus.nix
  ];
  mkSystem =
    path:
    let
      modules = [ path ] ++ nixosModules;
      configuration = lib.nixosSystem { inherit modules; };
      hostname = configuration.config.networking.hostName;
    in
    lib.nameValuePair hostname configuration;
in
lib.listToAttrs (map mkSystem systems)
