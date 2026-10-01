{
  config,
  pkgs,
  lib,
  ...
}:

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

  # 游戏工具
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-ng
  ];

  # gamemode: 可选的性能守护进程 (游戏经 libgamemode 请求 CPU/GPU 性能档),
  # gamescope / steam 都不依赖它 —— 装了只是让支持的游戏能用上
  programs.gamemode.enable = true;
}
