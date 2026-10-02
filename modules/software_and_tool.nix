{
  config,
  lib,
  pkgs,
  ...
}:

{
  # 允许非自由的软件源
  nixpkgs.config.allowUnfree = true;

  # perf / bpftrace 调试需要放宽 perf_event_paranoid, 但不必到最宽松的 -1:
  # 1 = 允许 per-process 的用户态 + 内核态采样, 仍禁止 system-wide 采样
  # (内核文档: Documentation/admin-guide/perf-security.rst)
  # 真需要 system-wide 时用 sudo, 或给 perf 二进制加 cap_perfmon, 而不是放开全系统
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

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

    # debugging: gdb 只在用户侧装 (home/dev.nix), 避免同名二进制互相遮蔽;
    # 需要以 root 调试时用 `nix shell nixpkgs#gdb` 即可
    rr
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
  # nix-ld: 让未打包的预编译二进制 (标准 ELF 解释器路径) 直接在宿主机运行
  # 缺库时往 libraries 里加; 需要完整 FHS 路径的程序仍用 `fhs` 沙箱
  programs.nix-ld = {
    enable = true;
    # 这里只需写上游默认清单里没有的: nixpkgs 已默认提供 zlib / zstd / stdenv.cc.cc
    # (libstdc++.so.6) / curl / openssl / attr / libssh / libxml2 / acl 等
    # (listOf 是合并语义, 重复列只会让最终清单里出现重复项)
    libraries = with pkgs; [
      libffi # 部分 manylinux wheel 会链接它, 上游默认清单里没有
      glibc # 少数预编译二进制需要比 nix-ld 自带 ld.so 更新的 glibc 符号
    ];
  };

  # 兼容路径: 部分面向通用 Linux 的预编译程序 (典型如 uv 下载的
  # python-build-standalone) 内部 ssl 硬编码查找 /etc/ssl/cert.pem,
  # 而 NixOS 的证书束在 /etc/ssl/certs/ca-bundle.crt;
  # 补一个软链, 否则这类程序的 https 请求报 SSLCertVerificationError
  environment.etc."ssl/cert.pem".source = "/etc/ssl/certs/ca-bundle.crt";
  # 文档: documentation.enable 与 man.enable 默认即 true, 这里只显式打开 dev 文档
  documentation.dev.enable = true;

  # 某些程序需要 SUID 包装器, 可以进一步配置或在用户会话中启动
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
