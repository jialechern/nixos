{ config, lib, pkgs, ... }:

{
  imports = [
    # 引入 bootloader
    ./modules/boot-loader.nix
    # 开启硬件图形化加速
    ./modules/hardware-graphics.nix
    # 引入 nix 配置
    ./modules/nix-config.nix
    # 引入网络配置
    ./modules/network.nix
    # 引入基本外设配置
    ./modules/peripherals.nix
    # 引入时区与语言配置
    ./modules/time-zone_and_language.nix
    # 引入桌面环境配置
    ./modules/desktop.nix
    # 引入输入法与字体配置
    ./modules/input-method_and_font.nix
    # 引入常见的系统级服务
    ./modules/service.nix
    # 引入系统必要的软件与工具
    ./modules/software_and_tool.nix
  ];
}
