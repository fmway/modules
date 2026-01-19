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
        #!${lib.getExe pkgs.fish}
        echo "{"
        bind --function-names | while read f; printf '  "%s" = "%s";\n' $f $f; end
        echo "}"
      '';
    };
  };
  flake = fmway-lib.fmway.genModules [ "nixosModules" "homeManagerModules" ] ./modules (fmway-lib // { inherit self inputs; });
}
