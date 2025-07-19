# don't strict packages
({ inputs, lib, flake-parts-lib, ... }: {
  disabledModules = [ "${inputs.flake-parts}/modules/packages.nix" ];
} // flake-parts-lib.mkTransposedPerSystemModule {
  name = "packages";
  option = lib.mkOption {
    type = with lib.types; lazyAttrsOf anything;
    default = { };
  };
  file = ./packages.nix;
})
