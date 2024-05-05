{
  description = "A dev environment for Figura";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = "${system}";
        };
      in rec {
        lib = import ./default.nix {
          inherit system;
          nixpkgs = pkgs;
        };
        devShell = import ./shell.nix {
          inherit pkgs;
        };
        devShells.ide = import ./shell.nix {
          inherit pkgs;
          ide = true;
        };
        defaultPackage = lib.minecraft."1.20.1";
      }
    );
}
