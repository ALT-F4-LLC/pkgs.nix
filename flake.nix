{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [self'.packages.dagger];
            nativeBuildInputs = [pkgs.just self'.packages.dagger];
          };
        };

        formatter = pkgs.alejandra;

        packages = {
          dagger = pkgs.callPackage ./pkgs/dagger {};
          steampipe = pkgs.callPackage ./pkgs/steampipe {};
        };
      };
    };
}
