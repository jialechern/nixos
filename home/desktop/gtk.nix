{ config, pkgs, ... }:

{
  # --- --- --- GTK 界面配置 --- --- ---
  gtk = {
    enable = true;

    # 设置深色模式
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;

    # 主题、图标及字体配置
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "mauve" ];
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "breeze_cursors";
      size = 24;
      package = pkgs.kdePackages.breeze;
    };

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    # GTK 3.0 特定配置
    gtk3.extraConfig = {
      # 启用按钮图标
      gtk-button-images = 1;
      # 启用菜单图标
      gtk-menu-images = 1;
      # 开启光标闪烁
      gtk-cursor-blink = 1;
      gtk-cursor-blink-time = 1000;
      # 开启过渡动画
      gtk-enable-animations = 1;
      # 点击进度条直接跳转
      gtk-primary-button-warps-slider = 1;
      # 工具栏同时显示图标和文字
      gtk-toolbar-style = 3;
      # 窗口按钮布局
      gtk-decoration-layout = "icon:minimize,maximize,close";
      # 声音主题
      gtk-sound-theme-name = "ocean";
      # 加载特定的 GTK 模块
      gtk-modules = "colorreload-gtk-module:window-decorations-gtk-module";
      # 强制设置 XFT DPI (120 DPI)
      gtk-xft-dpi = 122880;
    };

    # GTK 4.0 特定配置
    gtk4.theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "mauve" ];
      };
    };
    gtk4.extraConfig = {
      # 开启光标闪烁
      gtk-cursor-blink = 1;
      gtk-cursor-blink-time = 1000;
      # 开启过渡动画
      gtk-enable-animations = 1;
      # 点击进度条直接跳转
      gtk-primary-button-warps-slider = 1;
      # 窗口按钮布局
      gtk-decoration-layout = "icon:minimize,maximize,close";
      # 声音主题
      gtk-sound-theme-name = "ocean";
      # 强制设置 XFT DPI (120 DPI)
      gtk-xft-dpi = 122880;
    };
  };

  # 强制同步 GNOME 相关的深色模式设置
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # 深色模式的环境变量支持
  home.sessionVariables = {
    GTK_THEME = "catppuccin-mocha-mauve-standard";
  };
}
