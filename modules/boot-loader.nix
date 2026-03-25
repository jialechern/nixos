{ config, lib, pkgs, ... }:

{
  # 使用 systemd-boot EFI 引导加载器
  boot.loader = {
    # 使用 Grub2 和 Grub2 主题
    grub = {
      enable = true;
      # EFI 系统固定写 nodev
      device = "nodev";
      efiSupport = true;
      # 如果有双系统(比如 Windows), 它会自动扫描并添加到菜单
      useOSProber = true;

      # 指定主题包
      # # 使用 Catppuccin 主题
      # theme = pkgs.catppuccin-grub; 

      # 使用 Sleek 主题, 并利用 Nix 的 override 机制指定暗黑风格
      theme = pkgs.sleek-grub-theme.override { 
        # 支持: light, dark, orange, bigSur
        withStyle = "dark";
        # 自定义顶部文字
        withBanner = "Welcome to NixOS";
      };

      # 可选: 如果 4K/2K 屏幕下 GRUB 菜单显得太小, 可以强制指定分辨率
      gfxmodeEfi = "1920x1080"; 
    };

    # 彻底关闭默认的极简引导
    systemd-boot.enable = false;

    efi.canTouchEfiVariables = true;
  };

  # 使用最新内核
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
