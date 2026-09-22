{ config, pkgs, ... }:

{
  imports = [
    ./desktop/niri.nix
    ./desktop/gtk.nix
    ./desktop/qt.nix
    ./desktop/default-application.nix
    ./desktop/alacritty.nix
    ./desktop/kitty.nix
    ./desktop/fcitx5.nix
    ./desktop/rofi.nix
    ./desktop/swaylock.nix
    ./desktop/mpv.nix
    ./desktop/zathura.nix
    ./desktop/applications.nix

    # services
    ./desktop/services/wl-clip-persist.nix
    ./desktop/services/mako.nix
    ./desktop/services/polkit-agent.nix
    ./desktop/services/waybar.nix
    ./desktop/services/swayidle.nix
    ./desktop/services/wlsunset.nix
    ./desktop/services/wallpaper.nix

  ] ++ (builtins.filter builtins.pathExists [
    # 需要网络代理才能下载的应用列表配置
    ./desktop/applications-require-proxy.nix

    # keepassxc 配置
    ./desktop/keepassxc.nix
  ]);

  # --- --- --- 环境变量与会话同步 --- --- ---
  home.sessionVariables = {
    # 注意:
    # - 不要设置 XDG_CURRENT_DESKTOP: niri-session 自己会设置并在退出时清理,
    #   写在这里会泄漏到其它会话, 影响 portal 后端选择。
    # - 不要设置 GDK_BACKEND: niri 官方文档 (Important-Software) 明确警告
    #   全局设置该变量会破坏 screencast portal; GTK 自身会正确选择后端。
    # - 输入法变量 (XMODIFIERS / *_IM_MODULE) 见 modules/input-method_and_font.nix。
    # - Qt 平台主题由 qt.platformTheme 自动设置 (见 ./desktop/qt.nix)。

    # Wayland 环境中运行 Electron 应用必要的环境变量
    # (ELECTRON_ENABLE_FEATURES=WaylandWindowDecorations 已废弃: Electron 26+ 默认开启)
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
