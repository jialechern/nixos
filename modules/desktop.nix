{ config, pkgs, ... }:

{
  # --- 合成器与桌面环境 ---
  # programs.niri 还负责: session 注册/用户单元、gnome-keyring、swaylock 的 pam、
  # dconf、xdg-autostart, 以及 portal 的后端与接口路由
  programs.niri = {
    enable = true;

    # portal 的 FileChooser 交给 gtk 后端 (与 Thunar 一致, 也不拖入 nautilus)
    useNautilus = false;
  };

  # --- 配置一致性断言 ---
  # local-override.kdl 由 home/desktop/niri.nix 按主机生成; 仓库里同名文件会让
  # HM 的两处定义重叠 (默认静默保留仓库那份), 使本机覆盖项失效
  assertions = [
    {
      assertion = !(builtins.pathExists ./../dotfiles/niri/conf.d/local-override.kdl);
      message = ''
        请不要手写 dotfiles/niri/conf.d/local-override.kdl:
        它应由 home/desktop/niri.nix 按 hostName 生成。
      '';
    }
  ];

  services.greetd = {
    enable = true;

    # TUI greeter: 避免 systemd 启动日志打断界面
    useTextGreeter = true;

    settings = {
      # 不用 initial_session (它是免密自动登录), 只留 greeter + default_session
      default_session = {
        # --cmd 指定登录后启动的会话; 用绝对路径, 不依赖 greetd 的 PATH
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
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
  # 后端与接口路由交给 nixpkgs 的 programs.niri (生成 /etc/xdg/xdg-desktop-portal/
  # niri-portals.conf: gnome+gtk 后端, Secret 交 gnome-keyring);
  # 不要再写 xdg.portal.config —— ~/.config 下的同名文件会整体覆盖系统那份
  xdg.portal = {
    enable = true;
    # xdg-open 走 portal (FHS 沙箱等场景下更可靠)
    xdgOpenUsePortal = true;
  };

  #  启用 X11 窗口系统
  # services.xserver.enable = true;
}
