{
  description = "Kubernetes Playground";

  inputs = {
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {
    flake-utils,
    devshell,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlays.default
          ];
        };
      in {
        /*
        devshell, spin up a developer shell using `nix develop`
        */
        devShells.default = pkgs.devshell.mkShell {
          imports = [
            (pkgs.devshell.importTOML ./devshell.toml)
          ];
        };

        formatter = pkgs.alejandra;
      }
    );
}
