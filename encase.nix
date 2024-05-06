let
  inherit (builtins) concatMap isAttrs concatStringsSep map trace;
in
  {
    name,
    system ? builtins.currentSystem,
    pkgs ? import <nixpkgs> {},
    ro ? {nix = /nix;},
    rw ? {},
    wd ? /.,
    proc ? null,
    postBootstrap ? null,
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
    ifC = cond: cmd: if cond != null then cmd else "";
    textfile = { name, text, executable ? false }: derivation {

    }
    bootstrap = textfile {
      name = "${name}-encase-bootstrap.sh";
      text = ''
        #!${pkgs.bash}/bin/bash
        set -ex
        mount -Rr ${rootfs} $dir
        cd $dir
        ${ifC proc "mount -t proc proc ${toString proc}"}
        ${concatStringsSep "\n" (map ({ name, value }: "mount -Br ${toString value} ${"./" + (/. + name)}") roMounts)}
        ${concatStringsSep "\n" (map ({ name, value }: "mount -B  ${toString value} ${"./" + (/. + name)}") rwMounts)}
        unshare -R . -w ${toString wd} -- ${command}
      '';
      executable = true;
    };
    launch = textfile {
      name = "${name}-encase.sh";
      text = ''
        #!${pkgs.bash}/bin/bash
        set -ex
        export dir=$(mktemp -d)
        trap 'rm -rf $dir' EXIT
        cd $dir
        unshare -r -C unshare -n -i -u -T -p -f unshare -m ${bootstrap}
      '';
      executable = true;
    };
  in launch
