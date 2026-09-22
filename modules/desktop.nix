{ config, lib, pkgs, username, ... }:

{
  # --- 合成器与桌面环境 ---
  # 自动处理 Niri 的 Wayland session 注册
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "${username}";
      };

      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  security.polkit.enable = true;

  # --- pam 与 gnome-keyring ---
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # --- 屏幕共享与文件选择 ---
  # XDG Desktop Portals 是 Wayland 屏幕共享和文件选择的基础。
  # 后端与接口路由交给 nixpkgs 的 programs.niri 模块(见上方 enable)负责:
  # 它会安装 xdg-desktop-portal-gnome + -gtk, 并生成
  # /etc/xdg/xdg-desktop-portal/niri-portals.conf
  # (default=gnome;gtk, Access/Notification=gtk, Secret=gnome-keyring),
  # 文件选择器是否用 nautilus 由 programs.niri.useNautilus 控制。
  # 不要在此处或 Home Manager 里重复写 xdg.portal.config: portals.conf(5) 中
  # $XDG_CONFIG_HOME 优先级高于 $XDG_CONFIG_DIRS, 会整体覆盖系统那份配置,
  # 从而丢掉 Secret=gnome-keyring 等接口路由。
  xdg.portal = {
    enable = true;
    # 让 xdg-open 走 portal (FHS 沙箱等场景下打开链接更可靠)
    xdgOpenUsePortal = true;
  };

  #  启用 X11 窗口系统
  # services.xserver.enable = true;
}
