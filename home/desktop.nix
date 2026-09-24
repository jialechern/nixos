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
  ]);

  # --- --- --- 环境变量与会话同步 --- --- ---
  home.sessionVariables = {
    # 不要在此设置: XDG_CURRENT_DESKTOP (niri-session 自己管, 否则会泄漏到其它会话)、
    # GDK_BACKEND (官方警告会破坏 screencast portal)、输入法变量与 Qt 平台主题
    # (分别见 modules/input-method_and_font.nix、./desktop/qt.nix)

    # Electron 应用走 Wayland
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
