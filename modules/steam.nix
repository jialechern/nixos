{
  config,
  pkgs,
  lib,
  ...
}:

let
  # v2raya 的 HTTP 代理监听 (见 modules/service.nix; 仅监听回环)
  proxy = "http://127.0.0.1:20172";
  noProxy = "localhost,127.0.0.1,::1";
in
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;

    # 声明式注入代理, 不必再手动 `https_proxy=... steam`。
    # 原理: pkgs/by-name/st/steam/package.nix 会把 extraEnv 以
    # `set -a; ${lib.toShellVars extraEnv}` 写进 FHS 环境的 /etc/profile,
    # 该 profile 由容器内的 /init `source` 后再 exec steam; bwrap 未加
    # --clearenv, 所以变量一路传到 steam 客户端 / CEF / libcurl 下载以及它
    # 拉起的游戏进程 (桌面图标、终端、steam:// 链接、steam-gamescope 都走这个包)。
    # 注意:
    #   - HTTP 代理只接管 TCP/HTTP(S); 游戏的 UDP 联机流量不受影响, 仍直连
    #   - 大小写两套都设: libcurl 读小写, Chromium/CEF 与部分库读大写
    #   - no_proxy 保留回环, 免得 Steam 内部的本地 HTTP/IPC 流量被绕去代理
    #   - 想让游戏下载直连时, 把 steamcontent.com 等域名追加进 no_proxy
    package = pkgs.steam.override {
      extraEnv = {
        http_proxy = proxy;
        https_proxy = proxy;
        HTTP_PROXY = proxy;
        HTTPS_PROXY = proxy;
        no_proxy = noProxy;
        NO_PROXY = noProxy;
      };
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
