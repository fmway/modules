{ lib, ... }: let
  mkBind = initial: keys: initial // {
    inherit keys;
    commands = [];
    __functor = self: arg: self // (
      if builtins.isAttrs arg then
        arg
      else {
        commands = self.commands or [] ++ lib.fmway.flat arg;
      });
  };
  mkErase = initial: mkBind ({ erase = true; } // initial);
  op = { bind' = "preset"; bind_ = "user"; bind = null; };
  modes = [ "default" "insert" "replace" "replace_one" "visual" ];

  # TODO: set as type, so we don't need to add {} in last arg
  setsBind = lib.listToAttrs (lib.mapAttrsToList (name: operate: {
    inherit name;
    value = let
      i = lib.optionalAttrs (!isNull operate) { inherit operate; };
      r = lib.listToAttrs (map (x: {
        name = if isNull x then "__functor" else x;
        value = let
          i' = i // lib.optionalAttrs (!isNull x) { mode = x; };
          y = _: mkBind i';
        in if isNull x then y else { __functor = y; erase = mkErase i'; };
      }) ([ null ] ++ modes));
    in {
      erase = mkErase i;
    } // r;
  }) op);
in setsBind // {
  /* functionality for bind */
  c = lib.listToAttrs (map (name: {
    inherit name;
    value = x: lib.warn "c.${name} is deprecated, use functions.fish_commandline_${name} instead"
      "fish_commandline_${name} \"" + x + "\"";
  }) [ "append" "prepend" ]) // /* FIXME add other commands */ {
    
  };
  mkFn = cmd: {
    inherit cmd;
    args = [];
    __functor = self: arg: self // {
      args = self.args ++ [ arg ];
    };
    __toString = self: "${self.cmd} ${lib.escapeShellArgs self.args}";
  };
  defaultModes = modes;
}
