{ config, lib, pkgs, ... }:

{
  # 加载 NVIDIA 驱动
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # 必须开启, Wayland 合成器(如 Niri)和硬件加速强依赖此项
    modesetting.enable = true;

    # --- NVIDIA 显卡电源管理 ---
    # 如果电脑在休眠唤醒后出现黑屏, 尝试将此项改为 true
    powerManagement.enable = true;
    # 细粒度电源管理, 仅在某些现代笔记本(如带 Turing 架构及以后的显卡)上有效
    powerManagement.finegrained = false;

    # 使用 NVIDIA 的开源内核模块 (仅适用于 Turing 及之后的架构, 如 20/30/40 系)
    # 如果显卡比较老, 保持 false
    # 目前闭源驱动(false)在稳定性上依然略胜一筹
    # 使用闭源驱动
    open = false;

    # 开启 NVIDIA 设置菜单 (nvidia-settings)
    nvidiaSettings = true;

    # 选择驱动版本(通常 stable 即可, 老显卡可能需要 legacy_xx 版本)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # --- PRIME 混合显卡配置 ---
    prime = {
      # 模式 A 与 B 互斥, 只能选一个

      # # 模式 A: Offload 模式(推荐)
      # # 平时用 Intel 核显, 想用 NVIDIA 时手动指定(如: nvidia-offload steam)
      # offload = {
      # enable = true;
        # # 自动创建 nvidia-offload 脚本
      # enableOffloadCmd = true;

      # 模式 B: Sync 模式
      # 强行全程使用 NVIDIA, 显示器直接挂在独显上. 功耗高, 但在 Niri 下通常最稳
      sync.enable = true; 

      # 需要填入你机器真实的 PCI 总线 ID
      # 在命令行输入 `lspci | grep -E "VGA|3D"` 查看
      intelBusId = "PCI:0:2:0";   # 示例 ID, 请替换为自己的
      nvidiaBusId = "PCI:1:0:0";  # 示例 ID, 请替换为自己的
    };
  };

  # 针对 Niri/Wayland 的环境变量优化
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # 在 Sync 模式下，有时需要强制指定 WLR 后端以确保流畅度
    WLR_NO_HARDWARE_CURSORS = "1"; 
  };
}
