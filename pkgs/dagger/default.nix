{ stdenv, system }:

let
  getMetadata = s: {
    "aarch64-darwin" = { sha256 = "sha256:1wjy4aapagxvld2y8d4bbz36xl4xy2l8xyf0wfwl0b5ps2wkn55v"; system = "darwin_arm64"; };
    "aarch64-linux" = { sha256 = ""; system = "linux_arm64"; };
    "x86_64-darwin" = { sha256 = ""; system = "darwin_amd64"; };
    "x86_64-linux" = { sha256 = "sha256:1wjy4aapagxvld2y8d4bbz36xl4xy2l8xyf0wfwl0b5ps2wkn55v"; system = "linux_amd64"; };
  }.${s} or (throw "Unsupported system: ${s}");
  metadata = getMetadata system;
  name = "dagger";
  version = "v0.9.8";
in
stdenv.mkDerivation rec {
  inherit name version;
  src = builtins.fetchurl {
    sha256 = metadata.sha256;
    url = "https://github.com/dagger/dagger/releases/download/${version}/dagger_${version}_${metadata.system}.tar.gz";
  };
  unpackPhase = ''
    mkdir -p $out/bin
    tar -xzf $src -C .
    mv dagger $out/bin/dagger
  '';
}
