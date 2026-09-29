{ config, pkgs, ... }:

{
  # Qt 风格统一
  qt = {
    enable = true;
    # qtct = 同时安装 qt5ct 与 qt6ct, 并由 HM 设 QT_QPA_PLATFORMTHEME=qt5ct;
    # 该值对两个 Qt 主版本都命中: Qt5 侧是 qt5ct 的插件 key, Qt6 侧 qt6ct 的插件
    # 也注册了 "qt5ct" 别名 key (qt6ct 源码 src/qt6ct-qtplugin/qt6ct.json)。
    # 注意: "qt6ct" 不在 HM 的 platformPackages 枚举里, 只写它不会安装任何包
    # (平台主题插件缺失, 环境变量却照写), 所以这里必须用 qtct。
    platformTheme.name = "qtct";
    style.name = "kvantum"; # 启用更高级的 Catppuccin 风格主题

    # Catppuccin Mocha Kvantum 主题
    # 主题包安装到 ~/.config/Kvantum/, 并写入 kvantum.kvconfig 选中它
    kvantum = {
      enable = true;
      settings.General.theme = "catppuccin-mocha-mauve";
      themes = [
        (pkgs.catppuccin-kvantum.override {
          variant = "mocha";
          accent = "mauve"; # 与 GTK 主题的 mauve 强调色保持一致
        })
      ];
    };
  };

  # 字体包安装 (对应你的 tty-font 需求)
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono # NixOS 24.11+ 的新写法
  ];

  home.sessionVariables = {
    # 不设 QT_QPA_PLATFORM: Qt 6.5+ 会自动按 wayland→xcb 选平台, 硬写 "wayland"
    # 会让只支持 X11 的 Qt 程序起不来
    # QT_XCB_GL_INTEGRATION: 关闭走 xcb 的 Qt 程序的 GL 集成 (代价是软件渲染)
    QT_XCB_GL_INTEGRATION = "none";
  };
}
