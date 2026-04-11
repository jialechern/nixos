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
}
