{ config, pkgs, lib, ... }:

let
    alacrittyPath = /etc/nixos/home/alacritty;
in
{
    # --- --- --- 链接 niri 配置目录 --- --- ---

    # xdg.configFile."niri" = lib.mkIf (builtins.pathExists niriPath) {
    #     source = config.lib.file.mkOutOfStoreSymlink niriPath;
    # };

    xdg.configFile."alacritty".source = config.lib.file.mkOutOfStoreSymlink alacrittyPath;
}
