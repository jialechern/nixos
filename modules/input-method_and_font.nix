{ config, lib, pkgs, ... }:

{
  # --- 输入法(fcitx5) ---
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-anthy
        fcitx5-pinyin-moegirl
        fcitx5-pinyin-zhwiki
        fcitx5-material-color
        catppuccin-fcitx5
      ];
    };
  };

  # --- 输入法环境变量 ---
  # i18n.inputMethod (waylandFrontend) 只设 XMODIFIERS/QT_PLUGIN_PATH, 其余变量在此定义;
  # 不要设置 GDK_BACKEND —— 官方警告会破坏 screencast portal
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx"; # GTK2 / 走 XWayland 的 GTK 程序 / Electron
    QT_IM_MODULE = "fcitx"; # Qt5 及自带 Qt 输入法模块的程序 (Qt6 的 Wayland 原生输入走 text-input-v3)
    SDL_IM_MODULE = "fcitx"; # 默认走 X11 的 SDL2 程序
    GLFW_IM_MODULE = "ibus"; # GLFW 只实现了 ibus 协议 (fcitx5 兼容 ibus), 供部分游戏使用
  };

  # --- 字体配置 ---
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    noto-fonts
    nerd-fonts.jetbrains-mono
    source-han-serif
    source-han-sans
    libertine
    ibm-plex
  ];

  # 默认字体设置
  fonts.fontconfig = {
    defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [
        "JetBrainsMono Nerd Font Mono"
        "Sarasa Mono SC"
      ];
      sansSerif = [ "DejaVu Sans" "Noto Sans CJK SC" ];
      serif = [ "DejaVu Serif" "Noto Serif CJK SC" ];
    };
  };
}
