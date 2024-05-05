{ pkgs ? import <nixpkgs> {}, ide ? false }:
pkgs.mkShell {
  buildInputs = [pkgs.nix pkgs.git] ++ (if ide then [pkgs.bashInteractive] else []);
  shellHook = if ide then ''
    set -x
    exec ${pkgs.vscode-with-extensions.override {
      vscode = pkgs.vscodium;
      vscodeExtensions = with pkgs.vscode-extensions; [
        bbenoist.nix
      ];
    }}/bin/codium . --user-data-dir .vscode/usr
  '' else "";
}
