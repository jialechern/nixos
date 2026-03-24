# 编辑此配置文件以定义应在您的系统上安装哪些软件包.
# 如需帮助, 请查阅 configuration.nix(5) 手册页
# https://search.nixos.org/options 网站以及 NixOS 手册(可通过 `nixos-help` 命令查看)

{ config, lib, pkgs, inputs, username, ... }:

let
  v2rayAssets = pkgs.symlinkJoin {
    name = "v2ray-assets";
    paths = [
      pkgs.v2ray-geoip
      pkgs.v2ray-domain-list-community
    ];
  };
in
{
  imports = [
      # 包含硬件扫描结果
      ./hardware-configuration.nix
    ];

  # 复制 NixOS 配置文件并将其链接到生成的系统中
  # (/run/current-system/configuration.nix). 这在您意外删除 configuration.nix 文件时非常有用
  # system.copySystemConfiguration = true;

  # --- --- --- 引导与内核 --- --- ---
  # 使用 systemd-boot EFI 引导加载器
  boot.loader = {
    # 使用 Grub2 和 Grub2 主题
    grub = {
      enable = true;
      # EFI 系统固定写 nodev
      device = "nodev";
      efiSupport = true;
      # 如果有双系统(比如 Windows), 它会自动扫描并添加到菜单
      useOSProber = true;

      # 指定主题包
      # # 使用 Catppuccin 主题
      # theme = pkgs.catppuccin-grub; 

      # 使用 Sleek 主题, 并利用 Nix 的 override 机制指定暗黑风格
      theme = pkgs.sleek-grub-theme.override { 
        # 支持: light, dark, orange, bigSur
        withStyle = "dark";
        # 自定义顶部文字
        withBanner = "Welcome to NixOS";
      };

      # 可选: 如果 4K/2K 屏幕下 GRUB 菜单显得太小, 可以强制指定分辨率
      gfxmodeEfi = "1920x1080"; 
    };

    # 彻底关闭默认的极简引导
    systemd-boot.enable = false;

    efi.canTouchEfiVariables = true;
  };

  # 使用最新内核
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- --- --- 文件系统 --- --- ---
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/63088d49-836a-40b8-9e99-aa987455ca7f";
    fsType = "btrfs";
    options = [ 
      "defaults" 
      "compress=zstd"
      "autodefrag"
      "discard=async"
    ];
  };
  
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0abb0e77-a3f1-46e5-a054-3e0c48069f28";
    fsType = "btrfs";
    options = [
      "defaults"
      "compress=zstd"
      "autodefrag"
      "discard=async"
    ];
  };

  # --- --- ---  网络与 DNS --- --- ---
  # 定义您的主机名, 可随时修改
  networking.hostName = "nixos";

  # 通过 nmcli 或 nmtui 交互式配置网络连接
  networking.networkmanager.enable = true;

  # 本地域名解析
  networking.hosts = {
    "127.0.0.1" = [ "localhost" "${config.networking.hostName}.localdomain" "${config.networking.hostName}" ];
    "::1" = [ "localhost" ];
  };

  # DNS 服务器
  networking.nameservers = [
    "8.8.8.8"
    "2001:4860:4860::8888"
    "8.8.4.4"
    "2001:4860:4860::8844"
  ];

  # 配置网络代理(如有必要)
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # --- --- ---  地区与语言 --- --- ---
  # 设置您的时区
  time.timeZone = "Asia/Shanghai";

  # 选择国际化属性
  i18n.defaultLocale = "en_US.UTF-8";
  # i18n.defaultLocale = "zh_CN.UTF-8";

  # 特殊应用的语言设置
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
    LANG = "zh_CN.UTF-8";
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # --- --- --- 显卡与桌面环境 --- --- ---
  # --- 显卡驱动 ---
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    # 解决从休眠唤醒时的闪烁或崩溃问题
    powerManagement.enable = true; 
    # 使用 NVIDIA 的开源内核模块 (仅适用于 Turing 及之后的架构, 如 20/30/40 系)
    # 如果你的显卡比较老, 保持 false
    # 使用闭源驱动
    open = false;
    nvidiaSettings = true;
    # 必选, NVIDIA 驱动版本
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # 开启图形加速(尤其是 NVIDIA 显卡)
  hardware.graphics = {
    enable = true;
    # 必须开启 32 位支持, 否则 Steam 会崩溃
    enable32Bit = true;
  };

  # 启用 Steam 官方支持
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

  # XDG Desktop Portals 是 Wayland 屏幕共享和文件选择的基础
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  #  启用 X11 窗口系统
  # services.xserver.enable = true;

  # --- --- --- 基本外设 --- --- ---
  # --- 键盘布局 ---
  # 设置 Wayland 键盘布局
  services.xserver.xkb = {
    # 键盘布局
    layout = "us";
    # 变体(如 dvorak 等)
    variant = "";
    # 比如你想把 CapsLock 改成 Esc
    # options = "caps:escape";
 };

  # 确保控制台也使用同样的布局
  console.useXkbConfig = true;

  # 在 X11 中配置键盘布局
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # --- 打印服务 ---
  # 启用 CUPS 以打印文档
  services.printing.enable = true;

  # 如果你需要发现网络打印机
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  # 添加常见的打印机驱动
  services.printing.drivers = [ pkgs.gutenprint pkgs.hplip ];

  # --- 音频与蓝牙 ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # 启用声音支持
  # services.pulseaudio.enable = true;
  # 或者
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # 启用触摸板支持(在大多数桌面环境中默认已启用)
  services.libinput.enable = true;
  
  # --- --- --- 字体与输入法 --- --- ---
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

  # --- --- --- 统其它级服务--- --- ---
  # 列出您想要启用的服务:
  # --- ssh ---
  # 启用 OpenSSH 守护进程
  services.openssh.enable = true;

  # --- 防火墙 ---
  # 在防火墙中开放端口
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # 或者完全禁用防火墙
  # networking.firewall.enable = false;

  # --- 其它 ---
  # 电源管理
  services.tlp.enable = true;

  # 代理工具
  services.v2raya = {
    enable = true;
    # --- 把内核换成 xray ---
    cliPackage = pkgs.xray;
  };

  # --- 注入对应的 dat 数据库 ---
  systemd.services.v2raya.environment = {
    V2RAYA_V2RAY_ASSETSDIR = "${v2rayAssets}/share/v2ray";
  };

  # --- 容器与沙箱 ---
  # Docker/Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # 将 docker 命令别名指向 podman
  };
  # Flatpak
  services.flatpak.enable = true;

  # --- --- --- 全局 Nix 守护进程设置 --- --- ---
  nix = {
    settings = {
      # 每次构建错误时显示详细信息
      show-trace = true;
      # 开启实验性功能: Flakes 和新的 Nix 命令
      experimental-features = [ "nix-command" "flakes" ];
      # 国内镜像源
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
      # 可信的公钥
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      # 允许使用 nix 的用户和组
      trusted-users = [ "root" "@wheel" "@nix-users" ];
      # 自动优化 /nix/store 的磁盘使用
      auto-optimise-store = true;
      # 设为 false 后, 当配置文件没有 git commit 时, 不再弹出烦人的警告
      warn-dirty = false;
      # 限制构建任务使用的核心数 (根据的 CPU 自行调整, 0 为使用全部)
      max-jobs = "auto";
      cores = 0;
    };
  
    # 开启系统级的 nix 垃圾回收
    gc = {
      automatic = true;
      # 每七天运行一次垃圾回收
      dates = "weekly";
  
      # # 自动删除超过 7 天的世代
      # ptions = "--delete-older-than 7d";
    };
  
    registry = {
        # 将命令行的 nixpkgs 映射到 Flake 锁定的那个 nixpkgs
        # 前提是 home.nix 能接收到 flake 的 inputs 参数
        nixpkgs.flake = inputs.nixpkgs; 
    };
  };

  # --- nix 代理设置 ---
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:20172";
    https_proxy = "http://127.0.0.1:20172";
    ftp_proxy = "http://127.0.0.1:20172";
    no_proxy = "localhost,127.0.0.1,::1";
  };

  # --- --- --- 其它需要的系统级工具 --- --- ---
  # 允许非自由的软件源
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # 基础工具
    git
    wget
    curl
    rsync
    xdg-utils
    vulkan-tools
    man-pages
    man-pages-posix
    # 硬件监察
    nvme-cli
    pciutils
    lm_sensors
    bridge-utils
    libva-utils
    iw
    # xray 内核
    xray
    # 文件系统工具
    btrfs-progs
    exfat
    ntfs3g
    # 全局的文本编辑器
    neovim
    # XWayland 依赖
    xwayland-satellite
    xhost
    # 全局依赖
    libsecret
  ];

  # 很多 GTK 程序(包括 Niri 里的部分组件)依赖它存储设置
  programs.dconf.enable = true;
  # 如果在 Waybar 里看到网络图标
  programs.nm-applet.enable = true;
  # Shell
  programs.zsh.enable = true;
  programs.bash.enable = true;
  # 开启文档功能(man)
  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

  # 列出系统配置文件中安装的软件包。
  # 您可以使用 https://search.nixos.org/ 查找更多软件包(和选项)
  # environment.systemPackages = with pkgs; [
      # 别忘了添加编辑器来编辑 configuration.nix 文件！Nano 编辑器默认也已安装
  #   vim
  #   wget
  # ];

  # 某些程序需要 SUID 包装器, 可以进一步配置或在用户会话中启动
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  # --- --- --- 用户与组 --- --- ---
    users.groups.nix-users = { };
    users.users."${username}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "networkmanager" "wheel" "video" "audio" "nix-users" ];
    };

    users.users.root = {
      shell = pkgs.zsh;
    };

  # 定义用户账户. 别忘了用 `passwd` 命令设置密码
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # --- --- --- End --- --- ---
  # 此选项定义您在此特定机器上安装的第一个 NixOS 版本
  # 用于保持与在旧版 NixOS 上创建的应用程序数据(例如数据库)的兼容性
  #
  # 大多数用户在任何情况下都 **绝对不应** 在初始安装后更改此值, 即使您已将系统升级到新的 NixOS 发行版
  #
  # 此值 **不会** 影响您获取软件包和操作系统的 Nixpkgs 版本, 因此更改它 **不会** 升级您的系统——关于如何实际进行升级
  #
  # 要实际执行此操作
  #
  # 此值低于当前 NixOS 发行版版本 **并不** 意味着您的系统已过时、不受支持或存在安全漏洞
  #
  # **请勿** 更改此值, 除非您已手动检查了它将为您的配置带来的所有更改, 并相应地迁移了您的数据
  #
  # 更多信息，请参阅 `man configuration.nix` 或 https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "25.11";
}

