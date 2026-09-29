{ config, pkgs, lib, ... }:

{
  boot.kernelParams = [ "i915.enable_fbc=1" ];
  boot.initrd.kernelModules = [ "i915" ];

  # Intel 核显机器专用 (本文件只在纯核显的 hp 上被 import, 见 flake.nix):
  #   libvdpau-va-gl    让 libvdpau 走 VA-API 后端 (下面的 VDPAU_DRIVER=va_gl 需要它)
  #   i915.enable_fbc=1 强制打开帧缓冲压缩
  hardware.graphics.extraPackages = [ pkgs.libvdpau-va-gl ];

  environment.variables = {
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "iHD"; # intel-media-driver
  };
}
