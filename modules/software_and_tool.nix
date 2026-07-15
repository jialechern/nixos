{ config, lib, pkgs, ... }:

{
  # 允许非自由的软件源
  nixpkgs.config.allowUnfree = true;

  # 把 Linux 内核的 perf 访问限制放宽到最宽松的级别
  boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;

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
    # 虚拟机
    qemu # QEMU 本体
    dnsmasq # 默认虚拟网络需要
    virtiofsd # 共享文件夹支持
    # 网络代理工具内核
    v2ray
    xray
    sing-box
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

    # perf
    perf
    perf-tools

    # tracing / profiling
    bpftrace
    flamegraph
    valgrind
    kdePackages.kcachegrind

    # debugging
    gdbHostCpuOnly
    rr
    ltrace
    nixseparatedebuginfod2

    # process / system inspection
    sysstat
    procps
    htop
    iotop
    lsof
  ];

  # 很多 GTK 程序(包括 Niri 里的部分组件)依赖它存储设置
  programs.dconf.enable = true;
  # 如果在 Waybar 里看到网络图标
  programs.nm-applet.enable = true;
  # Shell
  programs.fish.enable = true;
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
}
