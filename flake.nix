{
  inputs = {
    fmway-lib.url = "github:fmway/lib";
  };

  outputs = { fmway-lib, self, ... } @ inputs:
    fmway-lib.fmway.genModules [ "nixosModules" "homeManagerModules" ] ./modules (fmway-lib // { inherit self inputs; }) //
    {
      lib = fmway-lib.fmway.treeImport {
        folder = ./lib;
        depth = 0;
        variables.lib = fmway-lib.lib;
      };
    };
}
