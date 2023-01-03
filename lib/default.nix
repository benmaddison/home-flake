{ self }:

let
  lib = self.inputs.nixpkgs.lib;

  typeOf = option: option.type;

  typeOfValues = option: let ty = typeOf option; in ty.nestedTypes.elemType;

  wrapOption = option: { ... } @ args: lib.mkOption ({
    inherit (option) type default description;
  } // args);

in {
  inherit typeOf typeOfValues wrapOption;

  import = path: import path { inherit self; };

  colors = import ./colors.nix;

  code = _lang: src: src;
}
