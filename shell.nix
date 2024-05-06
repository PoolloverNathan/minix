{
  pkgs ? import <nixpkgs> {},
  ide ? false,
  system ? builtins.currentSystem,
  extensions ?
    import
    (builtins.fetchGit {
      url = "https://github.com/nix-community/nix-vscode-extensions";
      ref = "refs/heads/master";
      rev = "c43d9089df96cf8aca157762ed0e2ddca9fcd71e";
    }),
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    git
    bashInteractive
    tree
    nix
    /*
                                           (writeScriptBin "nix" ''
      #!${pkgs.bash}/bin/bash
      cmd="''${1?}"
      shift
      if [[ $cmd == build ]]; then
        impure=--impure
      fi
      exec ${nix}/bin/nix "$cmd" $impure "$@"
    '')
    */
  ];
  shellHook =
    if ide
    then ''
      set -ex
      exec ${pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = with extensions.extensions.${system}; [
          vscode-marketplace.bbenoist.nix
          vscode-marketplace.dsrkafuu.vscode-theme-aofuji
        ];
      }}/bin/codium -w . --user-data-dir .vscode/usr
    ''
    else "";
}
