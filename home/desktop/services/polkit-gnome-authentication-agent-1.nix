{ config, pkgs, ... }:

{
  home.packages = [ pkgs.polkit_gnome ];

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      # 排在 graphical-session.target 之后: 这个代理需要图形会话 (X11/Wayland 连接),
      # 而 graphical-session-pre.target 早于 niri.service。
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      # 注意: Nixpkgs 中 polkit_gnome 的路径在 libexec 下
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
