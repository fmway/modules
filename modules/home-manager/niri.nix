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

    # TODO
    systemd = {
      enable = lib.mkEnableOption "Whether to enable {file}`sway-session.target` on niri startup";
      variables = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "SWAYSOCK"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
          "NIXOS_OZONE_WL"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
        ];
        example = [ "--all" ];
        description = ''
          Environment variables imported into the systemd and D-Bus user environment.
        '';
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."niri/config.kdl".text = cfg.finalConfig;
  };
}
