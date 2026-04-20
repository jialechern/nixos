{ config, pkgs, lib, dotfilesRoot, ... }:

{
  # --- --- --- 链接 ghostty 配置目录 --- --- ---
  xdg.configFile."ghostty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/ghostty";
    force = true;
  };
}
