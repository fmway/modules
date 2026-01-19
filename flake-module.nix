{ fmway-lib, self, lib ? fmway-lib.lib, ... } @ inputs:
lib.mkFlake' {
  inherit inputs;
  lib = fmway-lib.fmway.treeImport {
    folder = ./lib;
    depth = 0;
    variables.lib = fmway-lib.lib;
  };
  perSystem = { pkgs, ... }:
  {
    apps.get-list-functions-for-bind = lib.fmway.stringification' {
      type = "app";
      program = pkgs.writeScript "get-list-functions-for-bind.fish" /* fish */ ''
        #!/bin/env -S ${lib.getExe pkgs.fish} --no-config
        echo "{"
        echo '# ======== start bind specific ======='
        bind --function-names | while read f; printf '  "%s" = "%s";\n' $f $f; end
        echo '# ========= end bind specific ========'
        echo
        functions -a | string split ', ' | while read f; printf '  "%s" = "%s";\n' $f $f; end
        echo "}"
      '';
    };
  };
  flake = fmway-lib.fmway.genModules [ "nixosModules" "homeManagerModules" ] ./modules (fmway-lib // { inherit self inputs; });
}
