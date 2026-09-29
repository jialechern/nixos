{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- 文件管理器及其插件 ---
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler # 缩略图服务
    ffmpegthumbnailer # 视频缩略图
    gnome-keyring # 密码管理
    gvfs # 核心挂载服务 (包含 smb 支持)

    # --- 音视频流媒体 (PipeWire 相关工具) ---
    pavucontrol # 音量控制面板
    playerctl # 媒体控制命令行 (niri 常用)
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav

    # --- 桌面工具 ---
    brightnessctl # 亮度控制
    overskride # 蓝牙管理
    loupe # 图片查看器
    libnotify # 通知库
    firefox
    seahorse # 图形化 keyring 管理工具
    keepassxc # 密码管理器

    # --- 字体、主题与图标 ---
    (pkgs.catppuccin-gtk.override {
      variant = "mocha";
      accents = [ "mauve" ];
    }) # GTK 主题
    papirus-icon-theme # 图标主题
    # noto 字体 (cjk-sans / color-emoji) 由系统层 fonts.packages 统一提供,
    # 见 modules/input-method_and_font.nix, 此处不再重复安装

    # --- Latex && Typst 环境 ---
    typst
    texliveFull

    # --- 虚拟机 ---
    virt-manager
  ];
}
