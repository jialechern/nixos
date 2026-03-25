{ config, pkgs, ... }:

{
	programs.waybar = {
		enable = true;
		# 让 Home-Manager 通过 Systemd 用户服务来自动启动并守护 Waybar
		systemd.enable = true;

		# --- --- --- Waybar 主配置 --- --- ---
		settings = {
			mainBar = {
				# 基础布局与窗口属性
				layer = "top";            # [cite: 3]
				position = "top";         # [cite: 3]
				mod = "hide";             # 隐藏模式 [cite: 3]
				height = 34;              # 高度设置 [cite: 3]
				exclusive = true;         # 独占空间 [cite: 3]
				passthrough = false;      # 允许鼠标穿透 [cite: 3]
				"gtk-layer-shell" = true; # 启用 GTK Layer Shell 支持 [cite: 3]
				
				# 边距与间距
				spacing = 0;
				"margin-top" = 5;
				"margin-left" = 10;
				"margin-right" = 10;

				# 模块分布
				"modules-left" = [ "niri/workspaces" "niri/window" ];
				"modules-center" = [ "clock" "network" ];
				"modules-right" = [ 
					"tray" "cpu" "memory" "bluetooth" "keyboard-state" "battery" 
				];

				ipc = true;   # 启用 IPC 通信 [cite: 4]
				id = "bar-0"; # 标识符 [cite: 4]

				# --- 各模块详细配置 ---
				
				tray = {
					"icon-size" = 18; # 托盘图标大小 [cite: 4]
					spacing = 13;     # 托盘图标间距 [cite: 5]
				};

				clock = {
					format = " {:%H:%M}";		 # 时间格式 [cite: 5]
					"tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"; # [cite: 5]
				};

				network = {
					interval = 5;                                                                          # 刷新间隔 [cite: 5]
					"format-wifi" = "{essid} ({ipaddr})";                                                  # WiFi 格式 [cite: 5]
					"format-ethernet" = "󰈀 {ipaddr}";                                                      # 有线网格式 [cite: 5]
					"format-disconnected" = "⚠ Disconnected";                                              # 断开时格式 [cite: 5]
					"tooltip-format" = "{ifname} via {gwaddr} ";                                          # 提示框格式 [cite: 5]
					"tooltip-format-wifi" = "{essid} ({signaldBm}dBm) \nIP: {ipaddr}\nGateway: {gwaddr}"; # [cite: 6]
					"tooltip-format-ethernet" = "{ifname} \nIP: {ipaddr}";                                # [cite: 6]
					"on-click" = "nm-connection-editor";                                                   # 点击打开网络编辑器 [cite: 6]
				};

				cpu = {
					format = " {usage}%";		 # CPU 占用率 [cite: 6]
				};

				memory = {
					format = " {percentage}%"; # 内存占用率 [cite: 6]
				};

				bluetooth = {
					format = " {status}";		 # 蓝牙状态 [cite: 6]
					"format-connected" = " {device_alias}";		# 已连接状态 [cite: 6]
					"on-click" = "overskride";									# 点击调用蓝牙管理 [cite: 7]
				};

				"keyboard-state" = {
					numlock = true;           # [cite: 7]
					capslock = true;          # [cite: 7]
					format = "{name} {icon}"; # [cite: 7]
					"format-icons" = {
						locked = "";         # [cite: 7]
						unlocked = "";       # [cite: 7]
					};
				};

				battery = {
					states = {
						warning = 30;                         # 低电量警告阈值 [cite: 8]
						critical = 15;                        # 极低电量阈值 [cite: 8]
					};
					format = "{icon} {capacity}%";            # [cite: 8]
					"format-charging" = " {capacity}%";      # [cite: 8]
					"format-plugged" = " {capacity}%";       # [cite: 8]
					"format-alt" = "{icon} {time}";           # [cite: 8]
					"format-icons" = [ "" "" "" "" "" ]; # [cite: 8]
					"tooltip-format" = "{timeTo}";            # [cite: 8]
				};
			};
		};

		# --- --- --- 样式配置 (原 style.css 的内容完整注入) --- --- ---
		style = ''
			/* 定义 Nord 颜色变量 */
			@define-color polar-1 #2e3440; /* 背景暗色 */
			@define-color polar-4 #4c566a; /* 辅助暗色 */
			@define-color frost-1 #8fbcbb; /* 蓝绿色 */
			@define-color frost-2 #88c0d0; /* 浅蓝色 */
			@define-color frost-3 #81a1c1; /* 中蓝色 */
			@define-color frost-4 #5e81ac; /* 深蓝色 */
			@define-color snow-1	#d8dee9; /* 近白色 */

			* {
					font-family: "JetBrainsMono Nerd Font", "Fira Sans", sans-serif;
					font-size: 13px; /* 稍微大一点更清晰 */
					border: none;
					border-radius: 0;
			}

			#waybar {
					/* 更低的透明度：0.50 -> 0.35 */
					background: rgba(46, 52, 64, 0.35); 
					color: @snow-1;
					border-radius: 12px;
					/* 增加外边距，让 Bar 看起来是悬浮的 */
					margin: 5px 10px;
					transition-property: background-color;
					transition-duration: .5s;
			}

			/* 隐藏状态下的样式(如果开启了 hide 模式) */
			#waybar.hidden {
					opacity: 0.2;
			}

			/* 模块间距与 Nord 装饰 */
			.module {
					/* 加大间距：6px -> 12px */
					margin: 0 12px; 
					padding: 0 10px;
					background: transparent;
					transition: all 0.3s ease;
			}

			/* 悬停效果: 使用 Nord 蓝 */
			.module:hover {
					background: rgba(76, 86, 106, 0.4);
					color: @frost-2;
			}

			/* 针对特定模块的 Nord 化 */
			#workspaces button {
					color: @polar-4;
					padding: 0 5px;
			}

			#workspaces button.focused {
					color: @frost-3;
					background: rgba(255, 255, 255, 0.05);
					border-bottom: 2px solid @frost-3;
			}

			#cpu, #memory, #battery, #clock {
					color: @frost-2;
			}

			#network {
					color: @frost-1;
			}
		'';
	};
}
