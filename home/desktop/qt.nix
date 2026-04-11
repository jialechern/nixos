{ config, pkgs, ... }:

{
  # Qt 风格统一
  qt = {
    enable = true;
    platformTheme.name = "qt6ct"; # 让 Qt6 程序读取 qt6ct 的配置
    style.name = "kvantum"; # 启用更高级的 Nord 风格主题
  };

  # 字体包安装 (对应你的 tty-font 需求)
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono # NixOS 24.11+ 的新写法
  ];
}
