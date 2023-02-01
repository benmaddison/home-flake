{ self, python3, fetchFromGitHub }:

python3.pkgs.buildPythonApplication rec {
  pname = "oauth2ms";
  version = "a1ef0cabfdea57e9309095954b90134604e21c08";

  src = fetchFromGitHub {
    owner = "harishkrupo";
    repo = pname;
    rev = version;
    sha256 = "sha256-xPSWlHJAXhhj5I6UMjUtH1EZqCZWHJMFWTu3a4k1ETc=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    msal
    pyxdg
    python-gnupg
  ];

  format = "other";

  installPhase = ''
    mkdir -p $out/bin
    cp oauth2ms $out/bin/
  '';
}
