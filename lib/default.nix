{ self }:

{
  import = path: import path { inherit self; };

  colors = import ./colors.nix;
}
