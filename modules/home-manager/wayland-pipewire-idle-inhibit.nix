{ lib, pkgs, config, ... }: let
  cfg = config.programs.wayland-pipewire-idle-inhibit;
  toml = pkgs.formats.toml {};
in {
  options.programs.wayland-pipewire-idle-inhibit = {
    enable = lib.mkEnableOption "enable wayland-pipewire-idle-inhibit";
    package = lib.mkPackageOption pkgs "wayland-pipewire-idle-inhibit" {};
    settings = lib.mkOption {
      type = with lib.types; lazyAttrsOf anything;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."wayland-pipewire-idle-inhibit/config.toml".source =
      toml.generate "config.toml" cfg.settings;

    home.packages = [
      cfg.package
    ];
  };
}
