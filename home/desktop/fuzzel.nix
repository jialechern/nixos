{ config, pkgs, ... }:

{
	programs.fuzzel = {
		enable = true;
		
		# --- --- --- Fuzzel 配置 --- --- ---
		settings = {
			main = {
				# 字体配置
				font = "JetBrainsMono Nerd Font:size=16";

				# --- 布局设置 ---
				# 屏幕宽度百分比
				width = 60;
				# 显示行数
				lines = 12;
                # 水平内边距
				"horizontal-pad" = 24;
                # 垂直内边距
				"vertical-pad" = 12;

				# --- 外观属性 ---
                # 图标主题
				"icon-theme" = "Papirus-Dark";
                # 边框粗细
				"border-width" = 2;
                # 圆角半径
				rounding = 8;
			};

			# --- --- --- Nord 调色盘配置 --- --- ---
			colors = {
	            # 背景色和通明度
				background = "2e34405f";
                # 主文本色
				text = "d8dee9ff";
			    # 提示符
				prompt = "81a1c1ff";
	            # 占位符文本
				placeholder = "4c566aff";
				# 输入框文本
				input = "d8dee9ff";
				# 匹配高亮
				match = "b48eadff";
		        # 选中项背景
				selection = "3b4252ff";
	            # 选中项文本
				"selection-text" = "d8dee9ff";
                # 选中项匹配高亮
				"selection-match" = "8fbcbbff";
			    # 计数器颜色
				counter = "a3be8cff";
			    # 边框色
				border = "434c5eff";
			    # 强调色
				accent = "d08770ff";
			};
		};
	};
}
