{ pkgs, ... }:

{
  programs.swaylock = {
    enable = true;

    package = pkgs.swaylock-effects;

    settings = {
      # --- 基础功能 ---
      daemonize = true; # 锁定后以守护进程方式运行
      screenshots = true; # 使用屏幕截图作为背景
      clock = true; # 显示时钟
      indicator = true; # 始终显示解锁指示器
      indicator-idle-visible = true; # 空闲时也显示指示器
      ignore-empty-password = false; # 不允许空密码解锁
      show-failed-attempts = true; # 显示失败尝试次数
      show-keyboard-layout = false; # 隐藏键盘布局指示器(如 "English(US)")
      disable-caps-lock-text = false; # 显示大小写锁定状态文字
      indicator-caps-lock = true; # 指示器上显示大小写锁定状态
      submit-on-touch = true; # 触屏事件提交密码

      # --- 渐变进入动画 ---
      fade-in = 0.2; # 锁定画面淡入时间(秒)

      # --- 时间与日期格式 ---
      timestr = "%H:%M"; # 时间格式
      datestr = "%Y 年 %m 月 %d 日"; # 日期格式

      # --- 视觉特效(swaylock-effects 扩展) ---
      effect-blur = "10x5"; # 高斯模糊: 半径 x 次数
      effect-vignette = "0.45:0.45"; # 晕影效果: 基底:强度(0~1)
      effect-greyscale = false; # 不对背景做灰度处理

      # --- 指示器外观 ---
      indicator-radius = 320; # 指示器外圈半径(加大半径避免中文溢出)
      indicator-thickness = 12; # 指示器圆环粗细
      font = "Noto Sans CJK SC"; # 字体

      # swaylock-effects 的字体渲染硬编码逻辑:
      #   时间(timestr) = font-size,         默认 = arc_radius / 3 ≈ 107
      #   日期(datestr) = arc_radius / 6.0f, 固定 = 320 / 6 ≈ 53
      # 设置 font-size 时只影响时间字体, 日期字体不受 font-size 控制
      # 为了避免时间比日期小, 这里显式设置一个大于日期字号的合理值
      font-size = 80; # 时间字体大小 (日期固定 ≈ 53, 此处 80 > 53 确保时间更突出)

      # --- 线条样式 ---
      line-uses-ring = true; # 分割线颜色跟随圆环颜色
      separator-color = "00000000"; # 隐藏按键高亮段之间的分割线

      # ============================================================
      # Catppuccin Mocha 主题配色
      # 颜色格式:  RRGGBB 或 RRGGBBAA(不带 # 前缀)
      # ============================================================

      # --- 文本颜色 ---
      text-color = "cdd6f4"; # Text — 主文本色
      text-clear-color = "a6e3a1"; # Green — 密码正确
      text-ver-color = "89b4fa"; # Blue — 正在验证中
      text-wrong-color = "f38ba8"; # Red — 密码错误
      text-caps-lock-color = "fab387"; # Peach — 大小写锁定

      # --- 圆环(外圈)颜色 ---
      ring-color = "b4befe"; # Lavender — 默认外圈
      ring-clear-color = "a6e3a1"; # Green — 密码正确
      ring-ver-color = "89b4fa"; # Blue — 正在验证
      ring-wrong-color = "f38ba8"; # Red — 密码错误
      ring-caps-lock-color = "fab387"; # Peach — 大小写锁定

      # --- 内部填充颜色 ---
      inside-color = "1e1e2ebf"; # Base + 75% 不透明 — 默认
      inside-clear-color = "1e1e2ebf"; # Base + 75% — 正确
      inside-ver-color = "1e1e2ebf"; # Base + 75% — 验证中
      inside-wrong-color = "1e1e2ebf"; # Base + 75% — 错误
      inside-caps-lock-color = "1e1e2ebf"; # Base + 75% — 大小写锁定

      # --- 分割线颜色(line-uses-ring=true 时这些仅用于特定状态覆盖) ---
      line-color = "45475a"; # Surface1 — 默认分割线
      line-clear-color = "a6e3a1"; # Green — 正确
      line-ver-color = "89b4fa"; # Blue — 验证中
      line-wrong-color = "f38ba8"; # Red — 错误
      line-caps-lock-color = "fab387"; # Peach — 大小写锁定

      # --- 按键高亮颜色 ---
      key-hl-color = "cba6f7"; # Mauve — 当前按键高亮
      bs-hl-color = "f38ba8"; # Red — 退格键高亮
      caps-lock-key-hl-color = "fab387"; # Peach — 大小写锁定时的按键高亮
      caps-lock-bs-hl-color = "fab387"; # Peach — 大小写锁定时的退格高亮

      # --- 键盘布局提示框颜色 ---
      layout-bg-color = "1e1e2ebf"; # Base + 75% — 布局框背景
      layout-border-color = "b4befe"; # Lavender — 布局框边框
      layout-text-color = "a6adc8"; # Subtext0 — 布局框文字
    };
  };
}
