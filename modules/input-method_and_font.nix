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
  # nixpkgs 的 i18n.inputMethod (waylandFrontend = true) 只会设置 XMODIFIERS 与
  # QT_PLUGIN_PATH, 其余 toolkit 需要的输入法变量统一在这里定义一次。
  # 此前它们散落在 home/desktop/fcitx5.nix (HM sessionVariables) 与
  # dotfiles/niri/conf.d/env.kdl (niri environment {}) 两处, 行为还不一致 ——
  # niri 的 environment {} 只作用于 niri 启动的子进程, 不会传播到 systemd 服务。
  # 放在系统层的原因: pam_env 会在登录时注入 (greetd 会话同样生效), 同时也会并入
  # environment.variables 供登录 shell 使用。
  # 注意: 不要设置 GDK_BACKEND —— niri 官方文档明确警告全局设置会破坏 screencast portal。
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
