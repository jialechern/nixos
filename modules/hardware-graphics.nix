{ config, lib, pkgs, ... }:

{
  # --- 开启图形加速(尤其是 NVIDIA 显卡) ---
  hardware.graphics = {
    enable = true;
    # 必须开启 32 位支持, 否则 Steam 会崩溃
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Intel 核显的 VA-API 驱动 (omen 用不到, 但留在共享模块里让两机一致)
      intel-media-driver
      intel-vaapi-driver
      # 确保 Vulkan 支持(Steam 游戏必备)
      vulkan-loader
      vulkan-validation-layers
      # libvdpau-va-gl (VDPAU 的 VA-API 后端) 只在 Intel 机器上有意义, 已移到
      # modules/intel-extra.nix —— 它需配合 VDPAU_DRIVER=va_gl 使用
    ];
  };
}
