{ lib, ... }: let
  mkBind = initial: keys: x:
    if builtins.isAttrs x then
      { inherit keys; } // initial // x
    else mkBind (initial // {
      commands = initial.commands or [] ++ lib.fmway.flat x;
    }) keys;
  mkAll = fn:
    lib.fmway.listToFunction' (map fn modes);
  mkErase = initial: mkBind ({ erase = true; } // initial);
  op = { bind' = "preset"; bind_ = "user"; bind = null; };
  modes = [ "default" "insert" "replace" "replace_one" "visual" ];
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
      all = {
        __functor = _: mkAll (mode: setsBind.${name}.${mode});
        erase = mkAll (mode: setsBind.${name}.${mode}.erase);
      };
    } // r;
  }) op);
in setsBind // {
  /* functionality for bind */
  c = lib.listToAttrs (map (name: {
    inherit name;
    value = x:
      "fish_commandline_${name} \"" + x + "\"";
  }) [ "append" "prepend" ]) // /* FIXME add other commands */ {
    
  };
}
