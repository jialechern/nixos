{ config, pkgs, lib, dotfilesRoot, ... }:

{
  # --- --- --- 链接 alacritty 配置目录 --- --- ---
  xdg.configFile."alacritty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/alacritty";
    force = true;
  };
}
