{ config, pkgs, lib, ... }:

{
  boot.kernelParams = [ "i915.enable_fbc=1" ];
  boot.initrd.kernelModules = [ "i915" ];

  # Intel 核显专用: 避免与 dGPU 冲突
  environment.variables = {
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "iHD"; # intel-media-driver
  };
}
