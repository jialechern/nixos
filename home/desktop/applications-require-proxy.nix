{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Steam
    steam
    # Telegram 桌面端
    telegram-desktop
    # QQ
    qq
    # 微信
    wechat
    # WPS 中文版
    wpsoffice-cn
    # 开源办公套件
    libreoffice-stable
    # 几何画板
    geogebra6
    # GNU 图形处理工具
    gimp
    # p2p 下载器
    qbittorrent
    # 我的世界启动器
    prismlauncher
    # 桌面共享工具
    rustdesk-flutter
  ];

  # (OBS 配置不需要代理, 它的 import 已移到 home/desktop.nix)

  # Steam 配置
  xdg.desktopEntries = {
    steam-gamescope = {
      name = "Steam (gamescope)";
      # 用上游 programs.steam.gamescopeSession 生成的脚本 —— 它带 --steam 与
      # gamescopeSession.args / steamArgs 参数 (自写 `gamescope -- steam` 会漏掉这些)
      exec = "steam-gamescope";
      icon = "steam";
      terminal = false;
      categories = [ "Game" ];
    };
  };

}
