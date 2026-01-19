{
  inputs = {
    fmway-lib.url = "github:fmway/lib";
    nixpkgs.follows = "fmway-lib/nixpkgs";
  };

  outputs = { ... } @ inputs:
    import ./flake-module.nix inputs;
}
