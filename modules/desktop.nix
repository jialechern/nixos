{ config, lib, pkgs, username, ... }:

{
  # --- 启用 Steam 官方支持 ---
  programs.steam = {
    enable = true;
    # 针对 Niri/Wayland 建议开启这个
    remotePlay.openFirewall = true;
  };

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
  # XDG Desktop Portals 是 Wayland 屏幕共享和文件选择的基础
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  #  启用 X11 窗口系统
  # services.xserver.enable = true;
}
