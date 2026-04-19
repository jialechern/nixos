{ config, pkgs, lib, ... }:

let
  niriPath = "/etc/nixos/home/niri";
in
{
  # --- --- --- 链接 niri 配置目录 --- --- ---

  # xdg.configFile."niri" = lib.mkIf (builtins.pathExists niriPath) {
  #     source = config.lib.file.mkOutOfStoreSymlink niriPath;
  # };

  xdg.configFile."niri" = {
    source = config.lib.file.mkOutOfStoreSymlink niriPath;
    force = true;
  };
}
