{ config, pkgs, lib, ... }:

let
  alacrittyPath = /etc/nixos/home/alacritty;
in
{
  # --- --- --- 链接 alacritty 配置目录 --- --- ---

  # xdg.configFile."alacritty" = lib.mkIf (builtins.pathExists niriPath) {
  #     source = config.lib.file.mkOutOfStoreSymlink alacrittyPath;
  # };

  xdg.configFile."alacritty".source = config.lib.file.mkOutOfStoreSymlink alacrittyPath;
}
