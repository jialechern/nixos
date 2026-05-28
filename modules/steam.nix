{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;

    # gamescope 集成 (NixOS 24.11+)
    gamescopeSession.enable = true;

    # 声明式安装 GE-Proton, 自动出现在 Steam 兼容工具列表中
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Steam 需要的环境
  hardware.steam-hardware.enable = true;

  # 游戏工具
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-ng
  ];

  # gamescope 硬依赖: 内核能力
  programs.gamemode.enable = true;
}
