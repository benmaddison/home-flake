{ self }: { config, lib, ... }:

let
  cfg = config.local.colorscheme;
in
{
  options.local.colorscheme = {
    theme = lib.mkOption {
      type = lib.types.str;
    };
    hash = lib.mkOption {
      type = lib.types.anything;
      internal = true;
      readOnly = true;
    };
    hashHex = lib.mkOption {
      type = lib.types.anything;
      internal = true;
      readOnly = true;
    };
  };

  config.local.colorscheme = lib.listToAttrs (map
    (style: lib.nameValuePair style
      (self.lib.colors cfg.theme style))
    [ "hash" "hashHex" ]);
}
