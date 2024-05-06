# vim: ts=2 sw=2 et
{
  nixpkgs ?
    import ((import <nixpkgs> {}).fetchFromGitHub {
      owner = "nixos";
      repo = "nixpkgs";
      rev = "a1fd087b05f9061cb75d8e912d9cc879bb24ee2b";
      hash = sha256:t8w5qlp69MNXrBaOlqeU6xtFsAfwSDBZ062uVCy/waU=;
    }) {},
  system ? builtins.currentSystem,
}: let
  inherit (builtins) fetchurl fromJSON readFile toJSON placeholder replaceStrings;
  fetchJSON = a: fromJSON (readFile (fetchurl a));
  fetchJSONsha1 = sha1: url:
    fromJSON (readFile (nixpkgs.fetchurl {
      inherit url;
      hash = "sha1:" + sha1;
    }));
  inherit (nixpkgs.lib.attrsets) genAttrs;
in {
  minecraft = assert ## must be in --impure mode to run this build
  builtins ? currentSystem; let
    inherit (builtins) map listToAttrs trace abort;
    raw = fetchJSON "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json";
    gener = {
      id,
      url,
      ...
    }: {
      name = id;
      value = let fp = fetchurl url; in main id fp (fromJSON (readFile fp));
    };
    main = vers: fp: {
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
      nativesDownloader = builtins.fetchurl https://github.com/MidCoard/MinecraftNativesDownloader/releases/download/1.1/MinecraftNativesDownloader-1.1.jar;
      natives = execute "natives" ''
        ${nixpkgs.jdk17}/bin/java -jar ${nativesDownloader} --path ${fp}
        ls
        exit 1
      '';
      textfile = {
        name,
        text,
        executable ? false,
      }:
        derivation {
          inherit name;
          inherit system;
          text = text;
          inherit executable;
          passAsFile = ["text"];
          # builder = nixpkgs.coreutils + /bin/install;
          # args = ["-m" (if executable then 555 else 444) "--" (builtins.toFile name text) (builtins.placeholder "out")];
          builder = nixpkgs.bash + /bin/bash;
          inherit (nixpkgs) coreutils;
          args = [
            (builtins.toFile "textfile.sh" ''
              $coreutils/bin/cp $textPath $out
              test $executable && $coreutils/bin/chmod +x $out
            '')
          ];
        };
      execute = name: text: derivation {
        inherit name system;
        builder = textfile {
          name = "a"; #"${name}-script";
          # inherit text;
          text = "FOO";
          executable = true;
        };
      };
      libList = map ({
        name,
        rules ? [],
        downloads,
      }:
        with downloads.artifact;
          nixpkgs.fetchurl {
            inherit url;
            hash = "sha1:" + sha1;
          })
      libraries;
      java = nixpkgs.${"jdk" + toString javaVersion.majorVersion} + /bin/java;
      assets = with assetIndex; trace (fetchJSONsha1 sha1 url) null;
    in
      import ./encase.nix {
        name = "mc-${vers}";
        ro = {
          nix = /nix;
          natives = natives;
        };
        command = ''
          set -ex
          ${java} -Djava.library.path=/lib -cp ${builtins.concatStringsSep ":" ([(nixpkgs.fetchurl {inherit (downloads.client) url sha1;})] ++ map (a: a.outPath) libList)} ${mainClass} --accessToken none --version ${vers}
        '';
      };
  in
    listToAttrs (map gener raw.versions);
}
