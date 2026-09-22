{ config, pkgs, ... }:

{
  # --- --- --- GTK 界面配置 --- --- ---
  gtk = {
    enable = true;

    # 深色模式 (HM 同时写入 gtk3/gtk4 settings 与 dconf 的 color-scheme)
    colorScheme = "dark";

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

    # 光标主题由 home.pointerCursor (home.nix) 统一派生, 不在此重复声明

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
      # 不设 gtk-modules: 本机没有提供 colorreload / window-decorations 模块的包
      # 强制设置 XFT DPI (120 DPI)
      gtk-xft-dpi = 122880;
    };

    # GTK 4.0 特定配置
    # 显式声明以保留旧默认 (HM 26.05 起该项默认改为 null); 升 stateVersion 时再决定
    gtk4.theme = config.gtk.theme;
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

  # 深色模式的环境变量支持
  home.sessionVariables = {
    GTK_THEME = "catppuccin-mocha-mauve-standard";
  };
}
