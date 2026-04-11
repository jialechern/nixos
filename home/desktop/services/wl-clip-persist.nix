{ pkgs, ... }:

{
  # 安装必要的软件包
  home.packages = with pkgs; [
    wl-clipboard # 基础工具
    wl-clip-persist # 持久化工具
    cliphist # 历史管理器
  ];

  # 配置 wl-clip-persist 服务
  systemd.user.services.wl-clip-persist = {
    Unit = {
      Description = "Persistent clipboard for Wayland";
      # 确保在图形界面会话启动后再启动
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # 使用 --clipboard both 覆盖常规剪切板和鼠标选区 (primary)
      ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard both";
      Restart = "always";
      RestartSec = "5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # 配置 cliphist 监听服务
  # 这样你就不需要在 Niri 的 config.kdl 里手动写 spawn-at-startup 了
  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history service";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # 监听并存储剪切板历史
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "always";
      RestartSec = "5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # 图片剪切板监听服务
  systemd.user.services.cliphist-images = {
    Unit = {
      Description = "Clipboard history service (images)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "always";
      RestartSec = "5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
