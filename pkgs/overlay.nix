{ }:
final: prev:
let
  inherit (final) callPackage;
in
{
  oauth2ms = callPackage ./oauth2ms.nix { };
  cyrus-sasl-xoauth2 = callPackage ./cyrus-sasl-xoauth2.nix { };
  nord-rofi-theme = callPackage ./nord-rofi-theme.nix { };
}
