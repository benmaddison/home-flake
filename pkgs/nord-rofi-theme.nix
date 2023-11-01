{ self, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "nord-rofi-theme";
  version = "eebddcbf36052e140a9af7c86f1fbd88e31d2365";

  src = fetchFromGitHub {
    owner = "undiabler";
    repo = pname;
    rev = version;
    sha256 = "sha256-n/3O6WdMUImCcrS5UBXoWHZevYhmC8WkA+u+ETU2m1M=";
  };

  installPhase = /* bash */ ''
    mkdir -p $out
    cp nord.rasi $out/
  '';
}
