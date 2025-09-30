{ internal, lib, ... }:
{ config, pkgs, ... }: let
  cfg = config.wayland.windowManager.niri;
in {
  options.wayland.windowManager.niri = {
    enable = lib.mkEnableOption "enable niri window manager";
    package = lib.mkPackageOption pkgs "niri" {};
    config = lib.mkOption {
      description = "niri configurations, check https://github.com/sodiboo/niri-flake/blob/main/default-config.kdl.nix";
      type = with lib.types; listOf (mkOptionType {
        name = "kdl type";
        check = x: x ? name && x ? arguments && x ? properties && x ? children;
      });
      default = [];
    };
    finalConfig = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      description = "serialize from config";
      default = lib.kdl.serialize.nodes cfg.config;
    };
  };
  
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."niri/config.kdl".text = cfg.finalConfig;
  };
}
