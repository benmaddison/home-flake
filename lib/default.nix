{ lib }:
lib.extend (
  final: prev: rec {
    typeOf = option: option.type;

    typeOfValues =
      option:
      let
        ty = typeOf option;
      in
      ty.nestedTypes.elemType;

    wrapOption =
      option:
      { ... }@args:
      lib.mkOption (
        {
          inherit (option) type default description;
        }
        // args
      );

    filterFlatten =
      root: set:
      let
        inherit (final)
          isAttrs
          nameValuePair
          concatStringsSep
          mapAttrsToList
          listToAttrs
          filter
          ;
        flattenEach =
          path: key: value:
          let
            newPath = path ++ [ key ];
          in
          if isAttrs value then flatten newPath value else nameValuePair (concatStringsSep "." newPath) value;
        flatten = path: set: final.flatten (mapAttrsToList (flattenEach path) set);
      in
      listToAttrs (filter (x: x.value != null) (flatten root set));

    systemSourceLinksCommand = inputs: /* bash */ ''
      mkdir -p $out/source/inputs
      ${lib.concatStrings (
        lib.mapAttrsToList (name: source: /* bash */ ''
          ln -s ${source} $out/source/inputs/${name}
        '') inputs
      )}
    '';

    colors = import ./colors.nix;
  }
)
