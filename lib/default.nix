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

    findModules =
      let
        inherit (final)
          pipe
          readDir
          filterAttrs
          hasSuffix
          mapAttrsToList
          ;
        filterPredicate = name: type: type == "regular" && hasSuffix ".nix" name;
      in
      path:
      pipe path [
        readDir
        (filterAttrs filterPredicate)
        (mapAttrsToList (name: _: path + "/${name}"))
      ];

    mkSystems =
      path:
      { nixosModules }:
      let
        inherit (final)
          listToAttrs
          nameValuePair
          nixosSystem
          findModules
          ;
        systemConfigurations = findModules path;
        mkSystem =
          systemConfiguration:
          let
            evalConfiguration = nixosSystem {
              modules = nixosModules ++ [ systemConfiguration ];
            };
          in
          nameValuePair evalConfiguration.config.networking.hostName evalConfiguration;
      in
      listToAttrs (map mkSystem systemConfigurations);

    colors = import ./colors.nix;
  }
)
