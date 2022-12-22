theme: style:

let
  themes = {
    nord = let
      # polar night
      nord0  = "2e3440";
      nord1  = "3b4252";
      nord2  = "434c5e";
      nord3  = "4c566a";
      # snow storm
      nord4  = "d8dee9";
      nord5  = "e5e9f0";
      nord6  = "eceff4";
      # frost
      nord7  = "8fbcbb";
      nord8  = "88c0d0";
      nord9  = "81a1c1";
      nord10 = "5e81ac";
      # aurora
      nord11 = "bf616a";
      nord12 = "d08770";
      nord13 = "ebcb8b";
      nord14 = "a3be8c";
      nord15 = "b48ead";
    in {
      primary = {
        background     = nord0;
        foreground     = nord4;
        dim_foreground = "a5abb6";
      };
      normal = {
        black          = nord1;
        red            = nord11;
        green          = nord14;
        yellow         = nord13;
        blue           = nord9;
        magenta        = nord15;
        cyan           = nord8;
        white          = nord5;
      };
      bright = {
        black          = nord3;
        red            = nord11;
        green          = nord14;
        yellow         = nord13;
        blue           = nord9;
        magenta        = nord15;
        cyan           = nord7;
        white          = nord6;
      };
      dim = {
        black          = "373e4d";
        red            = "94545d";
        green          = "809575";
        yellow         = "b29e75";
        blue           = "68809a";
        magenta        = "8c738c";
        cyan           = "6d96a5";
        white          = "aeb3bb";
      };
      misc = {
        inherit
          nord0 nord1 nord2  nord3  nord4  nord5  nord6  nord7
          nord8 nord9 nord10 nord11 nord12 nord13 nord14 nord15
        ;
      };
    };
  };
  styles = {
    hex = _: c: c;
    hashHex = _: c: "#${c}";
  };
  applyStyle = _: colors: builtins.mapAttrs styles.${style} colors;
in builtins.mapAttrs applyStyle themes.${theme}
