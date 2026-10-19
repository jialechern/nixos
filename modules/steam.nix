{
  config,
  pkgs,
  ...
}:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;

    # 声明式注入代理, 不必再手动 `https_proxy=... steam`。
    # 原理: pkgs/by-name/st/steam/package.nix 会把 extraEnv 以 `set -a` +
    # `lib.toShellVars` 写进 FHS 环境的 /etc/profile, 容器内 /init `source` 后再
    # exec steam; bwrap 未加 --clearenv, 所以变量一路传到客户端 / CEF / libcurl
    # 下载以及它拉起的游戏进程 (桌面图标、终端、steam:// 链接、steam-gamescope
    # 都用这个包)。取值来自 modules/proxy.nix 的 machine.proxy.env, 想让下载直连
    # 就往那里的 noProxy 加域名。
    # 注意: HTTP 代理只接管 TCP/HTTP(S), 游戏 UDP 联机仍直连; no_proxy 已含回环,
    # 免得 Steam 内部的本地 HTTP/IPC 流量被绕去代理。
    package = pkgs.steam.override {
      extraEnv = config.machine.proxy.env;
    };

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
