{ self }:

{
  import = path: import path { inherit self; };
}
