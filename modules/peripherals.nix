{
  config,
  lib,
  pkgs,
  ...
}:

{
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

  # 网络打印机发现 (AirPrint / mDNS) 也需要 avahi —— 它统一在 modules/network.nix
  # 配置 (同一服务两处定义会让"谁生效 / 谁放行端口"变得难以排查), 这里不再重复

  # 添加常见的打印机驱动
  services.printing.drivers = [
    pkgs.gutenprint
    pkgs.hplip
  ];

  # --- 音频与蓝牙 ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # JACK 兼容层不再全局注入: services.pipewire.jack.enable 已被 nixpkgs 弃用
    # (PR #582717), 它把 pipewire 自带的 libjack.so.0 塞进整个会话的
    # LD_LIBRARY_PATH, 会压过各程序自身 RUNPATH 里的真 libjack2 (例如 fhs 沙箱
    # 的 multiPkgs)。需要用 JACK 的程序改成单独用 `pw-jack <命令>` 启动 —— 它的
    # wrapper 只对那一个进程临时设置 LD_LIBRARY_PATH。
    # 去掉后 PipeWire 的 jack.conf 与 JACK 协议支持照旧; alsa/pulse 已让
    # services.pipewire.audio.enable 保持默认 true, 不依赖 jack.enable。
  };

  # pw-jack 在 pipewire 的 jack output 里 (bin/pw-jack), 默认的 out output 不含它,
  # 所以显式安装; 这只是同一 pipewire 派生已构建的另一个 output, 不会额外编译
  environment.systemPackages = [ pkgs.pipewire.jack ];

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # 启用声音支持
  # services.pulseaudio.enable = true;
  # 或者
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # --- 存储设备 ---
  # udisks2: 让普通用户经 polkit 授权挂载/卸载可移动介质。yazi 的 M 键 (见
  # home/shell/yazi.nix 的 mount 插件) 与 thunar 都走它的 D-Bus 接口;
  # 客户端 udisksctl 在 home/shell/yazi.nix 声明, 这里提供守护进程端。
  # mountOnMedia 保持默认 false: 挂载点仍是 /run/media/$USER (ACL 控制)。
  services.udisks2.enable = true;

  # libinput: 本机 services.xserver.enable = false, 该模块在这里只装 libinput 的
  # udev 规则 (触摸板/鼠标的实际行为由 niri 的 input {} 决定, 见
  # home/desktop/niri/conf.d/input.kdl); 保留它只是为了那批 udev 规则
  services.libinput.enable = true;
}
