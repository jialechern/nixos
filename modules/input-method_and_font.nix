{ config, lib, pkgs, ... }:

{
  # --- 输入法(fcitx5) ---
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-anthy
      fcitx5-pinyin-moegirl
      fcitx5-pinyin-zhwiki
      fcitx5-material-color
      fcitx5-nord
    ];
  };

  # --- 字体配置 ---
  fonts.packages = with pkgs; [
    wqy_zenhei
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

