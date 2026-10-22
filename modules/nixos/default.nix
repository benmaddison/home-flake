{ lib, extraModules }:
let
  inherit (lib) findModules;
in
[
  ./base.nix
  ./users
]
++ (findModules ./platforms)
++ (findModules ./components)
++ extraModules
