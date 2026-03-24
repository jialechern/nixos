{ config, pkgs, lib, ... }:

let
    ghosttyPath = /etc/nixos/modules/ghostty;
in
{
    # --- --- --- 链接 niri 配置目录 --- --- ---

    # xdg.configFile."niri" = lib.mkIf (builtins.pathExists niriPath) {
    #     source = config.lib.file.mkOutOfStoreSymlink niriPath;
    # };

    xdg.configFile."ghostty".source = config.lib.file.mkOutOfStoreSymlink ghosttyPath;
}
