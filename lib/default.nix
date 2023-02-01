{ self }:

let
  lib = self.inputs.nixpkgs.lib;

  typeOf = option: option.type;

  typeOfValues = option: let ty = typeOf option; in ty.nestedTypes.elemType;

  wrapOption = option: { ... } @ args: lib.mkOption ({
    inherit (option) type default description;
  } // args);

  filterFlatten = root: set:
    let
      flattenEach = path: key: value:
        let newPath = path ++ [ key ]; in
        if lib.isAttrs value
        then flatten newPath value
        else lib.nameValuePair (lib.concatStringsSep "." newPath) value;
      flatten = path: set:
        lib.flatten (lib.mapAttrsToList (flattenEach path) set);
    in
    builtins.listToAttrs (builtins.filter (x: x.value != null) (flatten root set));

in
{
  inherit filterFlatten typeOf typeOfValues wrapOption;

  import = path: import path { inherit self; };

  colors = import ./colors.nix;

  code = _lang: src: src;

}
