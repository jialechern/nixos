{ pkgs, ... }:

{
  # --- polkit 认证代理 ---
  # 用 KDE 的 polkit-kde-agent-1 (niri wiki 推荐且上游在维护, 外观与 Qt 主题一致);
  # 包自带的 systemd/autostart 项在 niri 会话下不生效, 故自建单元
  home.packages = [ pkgs.kdePackages.polkit-kde-agent-1 ];

  systemd.user.services.polkit-kde-authentication-agent-1 = {
    Unit = {
      Description = "KDE PolicyKit Authentication Agent";
      # 需图形会话 (Wayland 连接), 故排在 graphical-session.target 之后
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      # KDE 包的可执行文件装在 libexec 下
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
