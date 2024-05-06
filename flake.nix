{
  description = "A dev environment for Figura";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    extensions,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          system = "${system}";
        };
      in rec {
        lib = import ./default.nix {
          inherit system;
          nixpkgs = pkgs;
        };
        devShells.default = import ./shell.nix {
          inherit pkgs system;
        };
        devShells.ide = import ./shell.nix {
          inherit pkgs system extensions;
          ide = true;
        };
        formatter = pkgs.alejandra;
        packages.default = lib.minecraft."1.20.1";
        packages.encase = import ./encase.nix {
          inherit pkgs system;
          name = "encase-test";
          ro = {
            bin = /bin;
            usr.bin = /usr/bin;
            nix = /nix;
          };
          rw = {
            tmp = /tmp;
          };
          command = "echo *";
        };
        apps.encase = {
          type = "app";
          program = "${packages.encase}";
        };
      }
    );
}
