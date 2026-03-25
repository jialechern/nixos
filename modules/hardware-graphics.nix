{ config, lib, pkgs, ... }:

{
  # --- 开启图形加速(尤其是 NVIDIA 显卡) ---
  hardware.graphics = {
    enable = true;
    # 必须开启 32 位支持, 否则 Steam 会崩溃
    enable32Bit = true;
    extraPackages = with pkgs; [
      # 如果是 Intel 核心
      intel-media-driver
      # 或者旧版 Intel
      intel-vaapi-driver
      # 确保 Vulkan 支持(Steam 游戏必备)
      vulkan-loader
      vulkan-validation-layers
      # # 如果是 AMD 核心，则通常不需要额外装这个
      # libvdpau-va-gl
    ];
  };
}
