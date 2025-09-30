{
  inputs = {
    fmway-lib.url = "github:fmway/lib";
  };

  outputs = { fmway-lib, self, ... } @ inputs:
    fmway-lib.fmway.genModules [ "nixosModules" "homeManagerModules" ] ./modules (fmway-lib // { inherit self inputs; });
}
