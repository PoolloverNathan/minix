# vim: ts=2 sw=2 et
{
  nixpkgs ? import ((import <nixpkgs> {}).fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "a1fd087b05f9061cb75d8e912d9cc879bb24ee2b";
    hash = sha256:t8w5qlp69MNXrBaOlqeU6xtFsAfwSDBZ062uVCy/waU=;
  }) {},
  system ? builtins.currentSystem,
}:
let
inherit (builtins) fetchurl fromJSON readFile toJSON placeholder replaceStrings;
fetchJSON = a: fromJSON (readFile (fetchurl a));
inherit (nixpkgs.lib.attrsets) genAttrs;
in {
  minecraft = let
    inherit (builtins) map listToAttrs trace abort;
    raw = fetchJSON "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json";
    gener = { id, url, ... }: { name = id; value = main (fetchJSON { inherit url; }); };
    main = {
        id,
        libraries,
        downloads,
        arguments,
        assetIndex,
        javaVersion,
        logging,
        mainClass,
        minimumLauncherVersion,
        ...
      }: let
        libList = trace arguments map ({
          name,
          rules ? [],
          downloads,
        }: with downloads.artifact;
        derivation {
          name = replaceStrings [":"] ["-"] name;
          inherit system;
          builder = nixpkgs.coreutils + /bin/install;
          args = ["-D" "-T" "--" (nixpkgs.fetchurl {
            inherit url;
            hash = "sha1:" + sha1;
          }) (placeholder "out" + "/" + path)];
        }) libraries;
        libs = trace javaVersion derivation {
          name = "${id}-libs";
          inherit system libList;
          builder = nixpkgs.writeScript "mc-libs-build.sh" ''
            #!${nixpkgs.bash}/bin/bash
            set -eu
            mkdir -p -- $out
            for l in $libList; do
              echo $l
              cp --no-preserve=all -vr "$l"/* $out/
            done
          '';
          PATH = nixpkgs.coreutils + /bin;
        };
        java = nixpkgs.${"jdk" + javaVersion.majorVersion} + /bin/java;
        assets = with assetIndex; {
          
        };
      in libs;
  in listToAttrs (map gener raw.versions);
} 
