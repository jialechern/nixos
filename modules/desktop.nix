{ config, pkgs, ... }:

{
  # --- 合成器与桌面环境 ---
  # programs.niri 一并负责: niri 包与 Wayland session 注册、niri.service 用户单元
  # (含 enableDefaultPath=false, 避免覆盖 niri-session 导入的 PATH)、gnome-keyring、
  # pam.services.swaylock、dconf、xdg-desktop-autostart, 以及 xdg.portal 的 niri 后端与接口路由
  programs.niri = {
    enable = true;

    # 不安装 nautilus: portal 的 FileChooser 改用 xdg-desktop-portal-gtk,
    # 与桌面用的 Thunar 风格一致, 也避免为了一个文件对话框拖入整个 nautilus
    useNautilus = false;
  };

  # --- 配置一致性断言 ---
  # dotfiles/niri/conf.d/local-override.kdl 由 home/desktop/niri.nix 按主机生成;
  # 若该文件同时存在于仓库里, Home Manager 会把 "目录递归软链" 与 "同路径单独定义"
  # 视为重叠, 默认保留仓库那份而静默忽略生成的这份 (home.fileOverlapResolution
  # 默认 "ignore"), 导致本机覆盖项 (显示器/渲染设备等) 默默失效。
  # 注意: 被 .gitignore 或尚未 git add 的文件不在 flake 源内, 本断言也不会看到,
  # 但那种情况下它同样不会被部署, 因此不会产生上述误导。
  assertions = [
    {
      assertion = !(builtins.pathExists ./../dotfiles/niri/conf.d/local-override.kdl);
      message = ''
        dotfiles/niri/conf.d/local-override.kdl 与按主机生成的同名文件冲突。
        请删除 dotfiles/niri/conf.d/local-override.kdl —— 它应由
        home/desktop/niri.nix 按 hostName 生成, 内容不应手写进仓库。
      '';
    }
  ];

  services.greetd = {
    enable = true;

    # tuigreet 是 TUI greeter: 打开开关避免 systemd 启动日志打断界面
    useTextGreeter = true;

    settings = {
      # 不使用 initial_session: 它的语义是免密码自动登录 (greetd 跳过 greeter
      # 直接进入会话, 且 greetd 每次重启都会再次免密登录), 故只保留 default_session
      default_session = {
        # tuigreet 是 greeter 本体, --cmd 指定登录后启动的会话;
        # 会话用绝对路径, 不依赖 greetd 服务的 PATH
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
