let
  inherit (builtins) concatMap isAttrs;
in
  {
    name,
    system ? builtins.currentSystem,
    pkgs ? import <nixpkgs> {},
    ro ? {nix = /nix;},
    rw ? {},
    command,
  }: let
    inherit (pkgs.lib.attrsets) attrsToList;
    findMounts = p: {...} @ a:
      concatMap
      ({
        name,
        value,
      }:
        if isAttrs value
        then findMounts (p + "/" + name) value
        else [{
          name = p + "/" + name;
          value = value;
        }])
      (attrsToList a);
    roMounts = findMounts "/" ro;
    rwMounts = findMounts "/" rw;
    rootfs = derivation {
      name = name + "-rootfs";
      inherit system;
      builder = pkgs.coreutils + /bin/mkdir;
      args =
        ["-p"]
        ++ map (a: builtins.placeholder "out" + "/" + a.name) (roMounts ++ rwMounts);
    };
  in
    pkgs.writeScript "encase.sh" ''
      #!${pkgs.bash}/bin/bash
      echo "TODO!"
      ${pkgs.tree}/bin/tree ${rootfs}
    ''
