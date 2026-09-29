{ config, lib, pkgs, ... }:

{
  # 使用 GRUB (EFI 模式) 引导
  boot.loader = {
    # 使用 Grub2 和 Grub2 主题
    grub = {
      enable = true;
      # EFI 系统固定写 nodev
      device = "nodev";
      efiSupport = true;
      # 如果有双系统(比如 Windows), 它会自动扫描并添加到菜单
      useOSProber = true;

      # 指定主题包: Sleek, 用 Nix 的 override 机制指定暗黑风格
      theme = pkgs.sleek-grub-theme.override {
        # 支持: light, dark, orange, bigSur
        withStyle = "dark";
        # 自定义顶部文字
        withBanner = "Welcome to NixOS";
      };

      # 已强制 1920x1080: 4K/2K 屏幕上 GRUB 默认菜单字号过小;
      # 若菜单比例异常, 改回 "auto" (或删掉本行) 让 GRUB 自行选择
      gfxmodeEfi = "1920x1080";
    };

    efi.canTouchEfiVariables = true;
  };

  # 用最新内核 (有意偏离上游默认的 linuxPackages, 换新硬件/新特性支持)。
  # 代价: nvidia stable 有时还没适配新内核 —— 若 rebuild 在构建 nvidia 内核模块时
  # 失败, 临时改回 pkgs.linuxPackages 或等 nvidia 跟上即可。
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
