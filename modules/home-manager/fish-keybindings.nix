{ lib, config, ... }: let
  cfg = config.programs.fish;
  bindOpts = lib.types.submodule ({ config, ... }: {
    options = {
      keys = lib.mkOption {
        type = with lib.types; either str (submodule {
          options.key = lib.mkOption {
            description = "Specify key name, not sequence";
            type = str;
          };
        });
      };
      commands = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
      };
      erase = lib.mkEnableOption "Erase mode";
      mode = lib.mkOption {
        description = "Specify the bind mode that the bind is used in";
        type = with lib.types; nullOr str;
        default = null;
      };
      setsMode = lib.mkOption {
        description = "Change current mode after bind is executed";
        type = with lib.types; nullOr str;
        default = null;
      };
      operate = lib.mkOption {
        description = ''
          Specify operate:
          - silent : Operate silently
          - preset : Operate on preset bindings
          - user   : Operate on user bindings
        '';
        type = with lib.types; nullOr (enum [ "user" "preset" "silent" ]);
        default = null;
      };
    };

    config = { };
  });

  vim = let
    shared_modes = map (x:
      "fish_default_key_bindings -M ${x}") cfg.vim.shared_mode;
    set_cursors = lib.mapAttrsToList (k: v:
      "set fish_cursor_${k} ${v}"
    ) cfg.vim.cursor;
    enable_vim = "fish_vi_key_bindings "
      + lib.optionalString cfg.vim.no_erase "--no-erase "
      + lib.optionalString (!isNull cfg.vim.initial_mode) cfg.vim.initial_mode;
  in {
    init = lib.concatStringsSep "\n" (
      lib.optionals (cfg.vim.shared_mode != []) shared_modes
    ++lib.optionals (cfg.vim.cursor != {}) set_cursors
    );
    run = enable_vim;
  };

  set_binds = lib.concatStringsSep "\n" (map (
    { keys, mode, setsMode, operate, commands, ... } @ v: let
      k  = if keys ? key then "-k ${keys.key}" else keys;
      op = lib.optionals (!isNull operate) [ "--${operate}" ];
      m  = lib.optionals (!isNull mode) [ "--mode" mode ];
      m' = lib.optionals (!isNull setsMode) [ "--sets-mode" setsMode ];
      erase = lib.concatStringsSep " " ([ "bind" k "--erase" ] ++ op ++ m ++ m');
      insert= lib.concatStringsSep " " ([ "bind" k ] ++ op ++ m ++ m' ++ map lib.escapeShellArg commands);
    in lib.concatStringsSep "\n" (
      lib.optionals v.erase [erase]
    ++lib.optionals (commands != []) [insert]
    )
  ) cfg.keybindings);
in {
  options.programs.fish = {
    keybindings = lib.mkOption {
      description = "fish keybindings";
      type = lib.types.listOf bindOpts;
      default = [];
    };
    vim = {
      enable = lib.mkEnableOption "enable vim binding";
      no_erase = lib.mkEnableOption "Don't resetting all bindings" // { default = true; };
      shared_mode = lib.mkOption {
        description = "list mode that allowed to use emacs binds";
        type = with lib.types; listOf str;
        default = [];
      };
      initial_mode = lib.mkOption {
        description = "Specify mode in startup shell";
        type = with lib.types; nullOr str;
        default = null;
      };
      cursor = lib.mkOption {
        description = "Specify cursor shape behavior";
        type = with lib.types; attrsOf (enum [ "block" "line" "underscore" ]);
        default = {};
      };
    };
  };

  config = {
    programs.fish.functions.fish_user_key_bindings = lib.mkMerge [
      (lib.mkIf cfg.vim.enable vim.init)
      (lib.mkIf cfg.vim.enable vim.run)
      (lib.mkIf (cfg.keybindings != {}) set_binds)
    ];
  };
}
