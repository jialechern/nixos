{ config, pkgs, lib, ... }:

let
    aichatPath = /etc/nixos/home/aichat;
in
{
    programs.aichat.enable = true;

    # --- --- --- 链接 aichat 配置目录 --- --- ---

    # xdg.configFile."aichat" = lib.mkIf (builtins.pathExists nvimPath) {
    #     source = config.lib.file.mkOutOfStoreSymlink nvimPath;
    # };

    xdg.configFile."aichat".source = config.lib.file.mkOutOfStoreSymlink aichatPath;
}
