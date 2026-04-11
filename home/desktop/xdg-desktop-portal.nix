{ config, pkgs, ... }:

{
  # --- --- --- XDG Desktop Portal 配置 --- --- ---
  xdg.portal = {
    enable = true;

    # 自动在 D-Bus 启动时更新环境变量
    xdgOpenUsePortal = true;

    # 安装必要的 Portal 后端
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    # Portal 行为优先级配置
    config = {
      niri = {
        # 默认基础功能使用 GTK
        default = [
          "gnome"
          "gtk"
        ];
        # 录屏、截图、远程桌面强制交给 GNOME 后端
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
      };

      sway = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      };

      # 兜底配置
      common = {
        default = [ "gtk" ];
      };
    };
  };
}
