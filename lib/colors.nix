theme:

let
  themes = {
    nord = {
      black        = "2e3440";
      red          = "bf616a";
      green        = "a3be8c";
      orange       = "d08770";
      blue         = "5e81ac";
      magenta      = "b48ead";
      cyan         = "88c0d0";
      light-grey   = "d8dee9";
      dark-grey    = "4c566a";
      light-red    = "bf616a";
      light-green  = "a3be8c";
      yellow       = "ebcb8b";
      light-blue   = "81a1c1";
      light-purple = "b48ead";
      teal         = "8fbcbb";
      white        = "eceff4";
    };
  };
  styles = {
    hex = _: c: c;
    hashHex = _: c: "#${c}";
  };
in style: builtins.mapAttrs styles.${style} themes.${theme}
