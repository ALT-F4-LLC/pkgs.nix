{
  fetchzip,
  stdenv,
  system,
}: let
  filterSystem = s:
    {
      "aarch64-darwin" = {
        extension = "zip";
        sha256 = "sha256-Ory3p69+uYpLPR3W97PJG0uukPYCClLH9rOzYh7k9vo=";
        system = "darwin_arm64";
      };
      "aarch64-linux" = {
        extension = "tar.gz";
        sha256 = "";
        system = "linux_arm64";
      };
      "x86_64-darwin" = {
        extension = "zip";
        sha256 = "";
        system = "darwin_amd64";
      };
      "x86_64-linux" = {
        extension = "tar.gz";
        sha256 = "sha256-tXnTnwf7OS5f6tFRZEl8UwxjuSmCj5EJwdGtxN4xbZk=";
        system = "linux_amd64";
      };
    }
    .${s}
    or (throw "Unsupported system: ${s}");
  metadata = filterSystem system;
  name = "steampipe";
  version = "v0.21.8";
in
  stdenv.mkDerivation rec {
    inherit name version;
    src = fetchzip {
      sha256 = metadata.sha256;
      url = "https://github.com/turbot/steampipe/releases/download/${version}/steampipe_${metadata.system}.${metadata.extension}";
    };
    installPhase = ''
      mkdir -p $out/bin
      mv steampipe $out/bin/steampipe
    '';
  }
