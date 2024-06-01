{ lib
, stdenv
, fetchFromGitHub
, fetchYarnDeps
, buildGoModule
, systemd
, yarn
, fixup_yarn_lock
, nodejs
}:

buildGoModule rec {
  pname = "grafana-alloy";
  version = "1.1.1";

  src = fetchFromGitHub {
    rev = "v1.1.1";
    owner = "grafana";
    repo = "alloy";
    hash = "sha256-jaOQG+QkVi10lUp6izvSGE9j76ULc4yKbxdDhLHykYI=";
  };

  vendorHash = "sha256-T48y1vhD1Z0pkTK77YJxcGmZnkrQClQOySoYgEYfyNo=";

  nativeBuildInputs = [ fixup_yarn_lock yarn nodejs ];

  ldflags =
    let
      prefix = "github.com/grafana/alloy/internal/build";
    in
    [
      "-s"
      "-w"
      # https://github.com/grafana/alloy/blob/3201389252d2c011bee15ace0c9f4cdbcb978f9f/Makefile#L110
      "-X ${prefix}.Branch=v${version}"
      "-X ${prefix}.Version=${version}"
      "-X ${prefix}.Revision=v${version}"
      "-X ${prefix}.BuildUser=nix"
      "-X ${prefix}.BuildDate=1980-01-01T00:00:00Z"
    ];

  tags = [
    "nonetwork" # disable network tests
    "nodocker" # disable docker tests
    "netgo"
    "builtinassets"
    "promtail_journal_enabled"
  ];

  subPackages = [
    "."
  ];

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/internal/web/ui/yarn.lock";
    hash = "sha256-o3vCI9GHCr4SjYsiT0wQ4mN76QeAGwOfLVCzGp7NMf4=";
  };

  preBuild = ''
    pushd internal/web/ui

    # Yarn wants a real home directory to write cache, config, etc to
    export HOME=$NIX_BUILD_TOP/fake_home

    fixup_yarn_lock yarn.lock
    yarn config --offline set yarn-offline-mirror ${yarnOfflineCache}
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive

    patchShebangs node_modules/

    yarn --offline build

    popd
  '';

  # uses go-systemd, which uses libsystemd headers
  # https://github.com/coreos/go-systemd/issues/351
  NIX_CFLAGS_COMPILE = lib.optionals stdenv.isLinux [ "-I${lib.getDev systemd}/include" ];

  # go-systemd uses libsystemd under the hood, which does dlopen(libsystemd) at
  # runtime.
  # Add to RUNPATH so it can be found.
  postFixup = lib.optionalString stdenv.isLinux ''
    patchelf \
      --set-rpath "${lib.makeLibraryPath [ (lib.getLib systemd) ]}:$(patchelf --print-rpath $out/bin/alloy)" \
      $out/bin/alloy
  '';

  meta = with lib; {
    description = "Open source OpenTelemetry Collector distribution with built-in Prometheus pipelines and support for metrics, logs, traces, and profiles";
    license = licenses.asl20;
    homepage = "https://grafana.com/oss/alloy";
    mainProgram = "alloy";
  };
}
