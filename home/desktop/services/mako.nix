{ config, pkgs, lib, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      # --- 基础布局设置 ---
      # 最大显示通知数
      max-visible = 5;
      # 按时间倒序排列
      sort = "-time";
      # 显示在最顶层
      layer = "top";
      # 锚定在右上角
      anchor = "top-right";

      # --- 样式设置 ---
      # 字体与大小
      font = "JetBrainsMono Nerd Font 17";
      # 通知框宽度
      width = 450;
      # 通知框高度
      height = 150;
      # 外边距
      margin = 20;
      # 内边距
      padding = 25;
      # 边框粗细
      border-size = 2;
      # 圆角半径
      border-radius = 8;
      # 启用图标
      icons = true;
      # 图标最大尺寸
      max-icon-size = 64;

      # --- Nord 调色盘配置 ---
      # 背景颜色
      background-color = "#2E34405F";
      # 文本颜色
      text-color = "#ECEFF4";
      # 边框颜色
      border-color = "#81A1C1";
      # 进度条颜色
      progress-color = "over #434C5E";

      # --- 交互设置 ---
      # 默认超时时间(毫秒)
      default-timeout = 5000;
      # 是否忽略应用建议的超时时间
      ignore-timeout = false;
    };

    # --- 高级样式与特定应用覆盖 ---
    extraConfig = ''
      			# 低优先级通知
      			[urgency=low]
      			border-color=#4C566A
      			default-timeout=2000

      			# 高优先级通知 (使用 Nord 11 Aurora Red)
      			[urgency=high]
      			width=600
      			border-size=4
      			padding=40
      			font=JetBrainsMono Nerd Font 23
      			border-color=#BF616A5F
      			default-timeout=0

      			# 针对特定应用 Overskride 的优化 (使用 Nord 15 Aurora Purple)
      			[app-name=Overskride]
      			border-color=#B48EAD
      		'';
  };

  # 定义 Systemd 用户服务来接管 Mako
  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # 使用 lib.getExe 自动获取 mako 的绝对路径
      ExecStart = "${lib.getExe pkgs.mako}";
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
