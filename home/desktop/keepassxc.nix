{ pkgs, config, dotfilesRoot, ... }:

{
  # 安装 KeePassXC 软件包
  home.packages = with pkgs; [
    keepassxc
  ];

  #  针对 Wayland (Niri) 的环境变量优化
  home.sessionVariables = {
    # 强制 KeePassXC 使用 Wayland 模式, 避免缩放模糊
    QT_QPA_PLATFORM = "wayland";
    # 如果使用自动输入 (Auto-type), Wayland 下可能需要特定的支持
    QT_XCB_GL_INTEGRATION = "none";
  };

  # --- --- --- 链接 keepassxc 配置目录 --- --- ---
  xdg.configFile."keepassxc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/keepassxc";
    force = true;
  };
}
