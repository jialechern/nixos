{ config, pkgs, lib, ... }:

let
    ghosttyPath = /etc/nixos/home/ghostty;
in
{
    # --- --- --- 链接 ghostty 配置目录 --- --- ---

    # xdg.configFile."ghostty" = lib.mkIf (builtins.pathExists niriPath) {
    #     source = config.lib.file.mkOutOfStoreSymlink ghosttyPath;
    # };

    xdg.configFile."ghostty".source = config.lib.file.mkOutOfStoreSymlink ghosttyPath;
}
