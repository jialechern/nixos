{ config, pkgs, lib, dotfilesRoot, ... }:

{
  # --- --- --- 链接 niri 配置目录 --- --- ---
  xdg.configFile."niri" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/niri";
    force = true;
  };
}
