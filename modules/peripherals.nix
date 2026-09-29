{ config, lib, pkgs, ... }:

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

  # libinput: 本机 services.xserver.enable = false, 该模块在这里只装 libinput 的
  # udev 规则 (触摸板/鼠标的实际行为由 niri 的 input {} 决定, 见
  # home/desktop/niri/conf.d/input.kdl); 保留它只是为了那批 udev 规则
  services.libinput.enable = true;
}
