{ pkgs ? import <nixpkgs> {}, ide ? false }:
pkgs.mkShell {
  buildInputs = with pkgs; [git bashInteractive tree (writeScriptBin "nix" ''
    #!${pkgs.bash}/bin/bash
    cmd="''${1?}"
    shift
    if [[ $cmd == build ]]; then
      impure=--impure
    fi
    ${nix}/bin/nix "$cmd" $impure "$@"
  '')];
  shellHook = if ide then ''
    set -ex
    exec ${pkgs.vscode-with-extensions.override {
      vscode = pkgs.vscodium;
      vscodeExtensions = with pkgs.vscode-extensions; [
        bbenoist.nix
      ];
    }}/bin/codium -w . --user-data-dir .vscode/usr
  '' else "";
}
