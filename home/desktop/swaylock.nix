{ pkgs, ... }:

{
	programs.swaylock = {
		enable = true;

        package = pkgs.swaylock-effects;
		
		# 所有的命令行参数都可以映射到 settings 中
		settings = {
			# --- 基础功能 ---
			daemonize = true;   # 对应脚本中的 -f
			screenshots = true; # 获取屏幕截图作为背景
			clock = true;       # 显示时钟
			indicator = true;   # 显示解锁指示器
			
			# --- 时间与日期格式 ---
			timestr = "%H:%M";
			datestr = "%Y年 %b %d日";

			# --- 视觉特效 ---
			effect-blur = "10x5";		 # 模糊强度
			effect-vignette = "0.45:0.45"; # 晕影效果
			
			# --- 指示器外观 ---
			indicator-radius = 270;
			indicator-thickness = 13;
            font = "Noto Sans CJK SC";
			font-size = 59;
			
			# --- Nord 调色盘颜色配置 ---
			# 注意：swaylock 通常要求 RRGGBB 或 RRGGBBAA 格式(不带 #)
			ring-color = "81a1c1";       # Nord 9 (冰蓝色)
			inside-color = "2e34405f";   # Nord 0 + 半透明
			text-color = "d8dee9";       # Nord 4
			key-hl-color = "88c0d0";     # Nord 8
			ring-wrong-color = "bf616a"; # Nord 11 (红色)
			
			# 辅助线条设置
			line-uses-ring = true;				# 线条颜色跟随圆环
			separator-color = "00000000";		# 隐藏分割线
		};
	};
}
