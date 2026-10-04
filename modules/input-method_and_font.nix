{
  config,
  lib,
  pkgs,
  ...
}:

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
  #
  # 已知风险 (保留是有意的): fcitx 官方 "Using Fcitx 5 on Wayland" 明确建议 Wayland 下
  # 不要设 GTK_IM_MODULE —— 设了 GTK3/4 会放弃原生 text-input-v3 通道改用 IM module。
  # 这里为了 Electron / 走 XWayland 的 GTK 程序仍能输入而保留;
  # 若发现 GTK 原生 Wayland 应用输入异常, 先删掉 GTK_IM_MODULE 再试。
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
        # CJK 等宽回退: 用 noto-fonts-cjk-sans 里实际安装的 Mono 版。
        # (原来写的是 "Sarasa Mono SC", 但仓库从未安装 sarasa-gothic, 该项一直
        #  静默回退到字体链的下一个 —— 2026-10-04 复评 P2-B3)
        "Noto Sans Mono CJK SC"
      ];
      sansSerif = [
        "DejaVu Sans"
        "Noto Sans CJK SC"
      ];
      serif = [
        "DejaVu Serif"
        "Noto Serif CJK SC"
      ];
    };
  };
}
