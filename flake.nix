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
        devShells.default = import ./shell.nix {
          inherit pkgs;
        };
        devShells.ide = import ./shell.nix {
          inherit pkgs;
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
          };
          rw = {
            tmp = /tmp;
          };
          command = "ls /";
        };
      }
    );
}
