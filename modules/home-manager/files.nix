{ lib, config, pkgs, ... }: let
  newGenFilesRecord = builtins.toFile "hm-new-gen" (
    builtins.concatStringsSep "\n" (
      builtins.filter (x: !builtins.any (y: x == y) config.backup.excludes) (
        builtins.attrNames cfg.file
      )
    )
  );
  noSymlinkRecord = builtins.toFile "hm-nosymlink-record" (
    builtins.concatStringsSep "\n" filteredNoSymlink
  );
  script.backup = pkgs.writeScript /* sh */ ''
    #!${lib.getExe pkgs.bash}
    p="${cfg.backup.postfix}"
    context="$1"

    if [ -e "$context$p" ];then
      i=1
      if [ -e "$context$p.$i" ]; then
        # FIXME sort only postfix.[0-9]+$
        all=( "$context$p."* )
        curr="$(grep -o -e "[0-9]\\+$" <<<"''${all[-1]}")"
        i="$(( curr + 1 ))"
      fi
      mv "$context$p" "$context$p.$i"
    fi
    mv "$context" "$context$p"
  '';

  optionType = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.symlink = lib.mkEnableOption "use symlink instead regular file, In some cases you need regular file to edit without rebuild" // { default = true; }; 
    });
  };
  filteredNoSymlink =  lib.filter (x: !cfg.file.${x}.symlink) (lib.attrNames cfg.file);
  isHaveNoSymlink = lib.length filteredNoSymlink > 0;
  cfg = config.home;
in {
  options = {
    home.backup.enable = lib.mkEnableOption "enable backup";
    home.backup.postfix = lib.mkOption {
      type = lib.types.str;
      default = "~";
      description = "postfix of the backup";
    };
    home.backup.excludes = lib.mkOption{
      type = with lib.types; listOf str;
      description = "exclude to backup";
      default = [];
    };
    home.file = optionType;
    xdg = lib.genAttrs [ "configFile" "dataFile" "stateFile" ] (_: optionType);
  };

  config = {
    home.activation = lib.mkMerge [
      (lib.mkIf cfg.backup.enable {
        smartBackup = lib.hm.dag.entryBefore [ "linkGeneration" ] /* sh */ ''
          #
          oldGenFiles="$(readlink -e "$oldGenPath/home-files")"
          newGenFiles="$(readlink -e "$newGenPath/home-files")"
          oldFiles="$(find "$oldGenFiles" -printf '%P\0')"
          while read record; do
            if ! grep "$record" &> /dev/null <<<"$oldFiles" && [ -e "$HOME/$record" ] && !${pkgs.diffutils}/bin/diff --brief --recursive "$HOME/$record" "$newGenFiles/$record" &>/dev/null; then
              ${script.backup} "$HOME/$record"
            fi
          done < "${newGenFilesRecord}"
        '';
      })
      (lib.mkIf isHaveNoSymlink {
        unlink = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] /* sh */ ''
          #
          newGenFiles="$(readlink -e "$newGenPath/home-files")"
          while read record; do
            if [ -e "$newGenFiles/$record" ]; then
              rm -rf "$HOME/$record"
              cp --dereference -r "$newGenFiles/$record" "$HOME/$record"
            fi
          done < "${noSymlinkRecord}"
        '';
      })
    ];
  };
}
