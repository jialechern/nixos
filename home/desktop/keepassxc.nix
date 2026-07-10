{ pkgs, config, dotfilesRoot, ... }:

{
  # 安装 KeePassXC 软件包
  home.packages = with pkgs; [
    keepassxc
  ];

  # --- --- --- 链接 keepassxc 配置目录 --- --- ---
  xdg.configFile."keepassxc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/keepassxc";
    force = true;
  };
}
