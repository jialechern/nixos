{
  ...
}:

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
      # 外边距: mako 的 margin 画在 surface *内部*(含透明边), niri 毛玻璃会涂满
      # 整块 surface -> 通知框外多出一圈模糊, 故置 0 并改用 layer-shell 的
      # outer-margin (位置不变)。margin 也是堆叠间隔, 置 0 后多条通知紧贴。
      margin = 0;
      outer-margin = 20;
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

      # --- Catppuccin Mocha 配色 ---
      # 背景颜色 (半透 → 毛玻璃可见)
      background-color = "#1E1E2EBF";
      # 文本颜色
      text-color = "#CDD6F4";
      # 边框颜色
      border-color = "#CBA6F780";
      # 进度条颜色
      progress-color = "over #45475A";

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
      			border-color=#6C7086
      			default-timeout=2000

      			# 高优先级通知
      			[urgency=high]
      			width=600
      			border-size=4
      			padding=40
      			font=JetBrainsMono Nerd Font 23
      			border-color=#F38BA880
      			default-timeout=0

      			# 针对特定应用 Overskride 的优化
      			[app-name=Overskride]
      			border-color=#CBA6F7
      		'';
  };

  # unit 不在这里声明: 直接用 mako 包自带的 share/systemd/user/mako.service
  # (Type=dbus + BusName + ExecCondition, 带 ExecReload, 随包更新); 它随包落在
  # /etc/profiles/per-user/$USER/share/systemd/user/ (useUserPackages) 后即可被
  # systemd --user 找到。配置热重载由上面 services.mako 的 onChange (makoctl reload) 负责。
}
