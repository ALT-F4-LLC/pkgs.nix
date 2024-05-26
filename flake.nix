{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      flake.nixosModules = import ./nixos;

      perSystem = { config, pkgs, ... }: {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [config.packages.dagger];
            nativeBuildInputs = [pkgs.just config.packages.dagger];
          };
        };

        formatter = pkgs.alejandra;

        packages = {
          alloy = pkgs.callPackage ./pkgs/alloy {};
          dagger = pkgs.callPackage ./pkgs/dagger {};
          steampipe = pkgs.callPackage ./pkgs/steampipe {};
        };
      };
    };
}
