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
      inherit name system text executable; passAsFile = ["text"];
      # builder = pkgs.coreutils + /bin/install;
      # args = ["-m" (if executable then 555 else 444) "--" (builtins.toFile name text) (builtins.placeholder "out")];
      builder = pkgs.bash + /bin/bash;
      inherit (pkgs) coreutils;
      args = [(builtins.toFile "textfile.sh" ''
        $coreutils/bin/cp $textPath $out
        test $executable && $coreutils/bin/chmod +x $out
      '')];
    };
    bootstrap = textfile {
      name = "${name}-encase-bootstrap.sh";
      text = ''
        #!${pkgs.bash}/bin/bash
        set -e
        mount -Rr ${rootfs} $dir
        cd $dir
        ${ifC proc "mount -t proc proc ${toString proc}"}
        ${concatStringsSep "\n" (map ({ name, value }: "mount -Rr ${toString value} ${"." + toString (/. + name)}") roMounts)}
        ${concatStringsSep "\n" (map ({ name, value }: "mount -R  ${toString value} ${"." + toString (/. + name)}") rwMounts)}
        unshare -R . -w ${toString wd} -- ${pkgs.bash}/bin/bash ${textfile { inherit name; text = command; executable = true; }}
      '';
      executable = true;
    };
    launch = textfile {
      name = "${name}-encase.sh";
      text = ''
        #!${pkgs.bash}/bin/bash
        set -e
        export dir=$(mktemp -d)
        trap 'rm -rf $dir' EXIT
        cd $dir
        unshare -r -C unshare -n -i -u -T -p -f unshare -m ${bootstrap}
      '';
      executable = true;
    };
  in launch
