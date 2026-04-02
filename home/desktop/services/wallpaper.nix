{ config, pkgs, lib, ... }:

{
  # 安装壁纸工具链: awww(后端渲染) + waypaper(前端管理)
  home.packages = [
    pkgs.awww
    pkgs.waypaper
  ];
  # awww 系统服务配置
  systemd.user.services.awww = {
    Unit = {
      Description = "awww 壁纸守护进程";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # 启动命令: 指定缓存目录并忽略首次缓存读取错误
      ExecStart = ''${pkgs.awww}/bin/awww-daemon \
        --cache-dir ${config.home.homeDirectory}/.cache/awww \
        --log-level warn'';
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
