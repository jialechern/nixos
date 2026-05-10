{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Telegram 桌面端
    telegram-desktop
    # QQ
    qq
    # 微信
    wechat
    # WPS 中文版
    wpsoffice-cn
    # 开源办公套件
    libreoffice-fresh
    # 几何画板
    geogebra6
    # GNU 图形处理工具
    gimp
    # p2p 下载器
    qbittorrent
    # Steam
    steam
    # 我的世界启动器
    prismlauncher
    # # 桌面共享工具
    rustdesk-flutter
  ];

  imports = [

    ./obs.nix

  ];

}
