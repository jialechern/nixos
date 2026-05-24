{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";

        # dock 模式: 窗口被"挤下来", 不透传点击事件
        mode = "dock";

        # ── 布局模式: dock 模式下窗口会被推下来 ──
        exclusive = true;
        passthrough = false;

        # ── 顶栏尺寸 ──
        height = 44;
        spacing = 0;

        # ── 固定居中: 时钟严格居中不随两侧模块偏移 ──
        "fixed-center" = true;

        # ── 外边距: 使顶栏不贴屏幕边缘 ──
        "margin-top" = 6;
        "margin-left" = 12;
        "margin-right" = 12;

        # ── 模块布局 ──
        "modules-left" = [ "niri/workspaces" "niri/window" ];
        "modules-center" = [ "clock" ];
        "modules-right" = [
          "tray"
          "network"
          "cpu"
          "memory"
          "bluetooth"
          "keyboard-state"
          "battery"
        ];

        # IPC 接口: 允许外部程序控制 waybar
        ipc = true;
        id = "bar-0";

        # ═══════════════════════════════════════════════
        # 系统托盘
        # ═══════════════════════════════════════════════
        tray = {
          "icon-size" = 20;
          spacing = 10;
        };

        # ═══════════════════════════════════════════════
        # 时钟
        # ═══════════════════════════════════════════════
        clock = {
          interval = 1;
          # 完整日期 + 时间格式
          format = " {:%Y-%m-%d  %H:%M:%S}";
          # 左键切换为短格式
          "format-alt" = "{:%m-%d %H:%M}";
          "tooltip-format" = "<big>{:%Y年%B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        # ═══════════════════════════════════════════════
        # 工作区 (niri)
        # 关键: all-outputs = false, 每个显示器只显示自己
        #       的工作区, 解决多显示器工作区混乱问题
        # ═══════════════════════════════════════════════
        "niri/workspaces" = {
          # 显示图标 + 工作区索引
          format = "{icon}  {index}";

          # 工作区状态图标
          "format-icons" = {
            # 空工作区 (无窗口)
            "empty" = "";
            # 非活跃工作区
            "default" = "";
            # 当前活跃 (有焦点) 工作区
            "active" = "";
            # 紧急提示工作区
            "urgent" = "";
          };

          # 多显示器修复
          "all-outputs" = false;
        };

        # ═══════════════════════════════════════════════
        # 当前窗口标题
        # ═══════════════════════════════════════════════
        "niri/window" = {
          format = "{title}";

          # 最大显示长度
          "max-length" = 72;

          rewrite = {
            "(.*) - Mozilla Firefox" = "󰈹 $1";
            "(.*) - Chromium" = "󰊯 $1";
            "(.*) - Google Chrome" = "󰊯 $1";
            "(.*) - Visual Studio Code" = "󰨞 $1";
            "(.*) - VSCodium" = "󰨞 $1";
            "(.*) - Code" = "󰨞 $1";
            "(.*) - Discord" = "󰙯 $1";
            "(.*) - Spotify" = "󰓇 $1";
            "(.*) - kitty" = " $1";
            "(.*) - alacritty" = " $1";
            "(.*) - ghostty" = " $1";
          };
        };

        # ═══════════════════════════════════════════════
        # 网络
        # ═══════════════════════════════════════════════
        network = {
          interval = 5;
          "format-wifi" = "󰖩 {essid}";
          "format-ethernet" = "󰈀 {ipaddr}";
          "format-disconnected" = "󰌙 断连";
          "tooltip-format" = "{ifname} via {gwaddr} 󰛳";
          "tooltip-format-wifi" = "{essid} ({signaldBm}dBm)\nIP: {ipaddr}\n网关: {gwaddr}";
          "tooltip-format-ethernet" = "{ifname}\nIP: {ipaddr}";
          "tooltip-format-disconnected" = "网络已断开";
          "on-click" = "nm-connection-editor";
        };

        # ═══════════════════════════════════════════════
        # CPU
        # ═══════════════════════════════════════════════
        cpu = {
          interval = 2;
          format = "󰍛 {usage}%";
          # 左键切换为负载均值 (1分钟)
          "format-alt" = "󰍛 {load1}";
          # 负载阈值, 超过后自动添加对应的 CSS 类
          states = {
            warning = 70;
            critical = 90;
          };
          "tooltip-format" = "CPU: {usage}%\n平均负载: {load1}";
        };

        # ═══════════════════════════════════════════════
        # 内存
        # ═══════════════════════════════════════════════
        memory = {
          interval = 5;
          format = " {percentage}%";
          "format-alt" = " {used}G/{total}G";
          states = {
            warning = 70;
            critical = 90;
          };
          "tooltip-format" = "已用: {used} GB\n总量: {total} GB\n可用: {avail} GB";
        };

        # ═══════════════════════════════════════════════
        # 蓝牙
        # ═══════════════════════════════════════════════
        bluetooth = {
          format = "󰂲 关闭";
          "format-connected" = "󰂱 {device_alias}";
          "format-connected-battery" = "󰂱 {device_alias} 󱊣{device_battery_percentage}%";
          "tooltip-format" = "蓝牙适配器: {controller_alias}\n已连接: {num_connections} 个设备";
          "tooltip-format-connected" = "{controller_alias}\n\n已连接设备:\n{device_enumerate}";
          "tooltip-format-enumerate-connected" = "   {device_alias}";
          "tooltip-format-enumerate-connected-battery" = "   {device_alias} 电量 {device_battery_percentage}%";
          "on-click" = "overskride";
        };

        # ═══════════════════════════════════════════════
        # 键盘状态指示 (NumLock / CapsLock)
        # ═══════════════════════════════════════════════
        "keyboard-state" = {
          numlock = true;
          capslock = true;

          # 分键显示 (Waybar 0.10+)
          format = {
            numlock = "N {icon}";
            capslock = "C {icon}";
          };

          "format-icons" = {
            locked = "";
            unlocked = "";
          };
        };

        # ═══════════════════════════════════════════════
        # 电池
        # ═══════════════════════════════════════════════
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };

          format = "󰁾 {capacity}%";
          "format-charging" = "󰂄 {capacity}%";
          "format-plugged" = "󱐋 {capacity}%";
          # 电量充满
          "format-full" = "󰁹 满电";

          # 右键切换为剩余时间预估
          "format-alt" = "{icon} {time}";
          "format-icons" = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          "tooltip-format" = "电量: {capacity}%\n剩余时间: {time}";
        };
      };
    };

    style = ''
      /* ══════════════════════════════════════════════════════
         Catppuccin Mocha 配色变量
         ══════════════════════════════════════════════════════ */
      @define-color rosewater #f5e0dc;
      @define-color flamingo  #f2cdcd;
      @define-color pink      #f5c2e7;
      @define-color mauve     #cba6f7;
      @define-color red       #f38ba8;
      @define-color maroon    #eba0ac;
      @define-color peach     #fab387;
      @define-color yellow    #f9e2af;
      @define-color green     #a6e3a1;
      @define-color teal      #94e2d5;
      @define-color sky       #89dceb;
      @define-color sapphire  #74c7ec;
      @define-color blue      #89b4fa;
      @define-color lavender  #b4befe;
      @define-color text      #cdd6f4;
      @define-color subtext1  #bac2de;
      @define-color subtext0  #a6adc8;
      @define-color overlay2  #9399b2;
      @define-color overlay1  #7f849c;
      @define-color overlay0  #6c7086;
      @define-color surface2  #585b70;
      @define-color surface1  #45475a;
      @define-color surface0  #313244;
      @define-color base      #1e1e2e;
      @define-color mantle    #181825;
      @define-color crust     #11111b;

      /* ── 全局基础样式 ── */
      * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK SC", sans-serif;
        font-size: 14px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      /* ── 顶栏本体: 全透明背景 + 底部阴影 ── */
      window#waybar {
        background: transparent;
        color: @text;
        box-shadow: 0px 5px 7px 5px rgba(0, 0, 0, 0.55);
        transition-property: background-color, box-shadow;
        transition-duration: 0.3s;
      }

      /* ── 无窗口时隐藏窗口标题模块 ── */
      window#waybar.empty #window {
        background: transparent;
        box-shadow: none;
        padding: 0;
        margin: 0;
      }

      /* ── 工具提示 ── */
      tooltip {
        background: rgba(30, 30, 46, 0.96);
        border: 1px solid rgba(88, 91, 112, 0.75);
        border-radius: 14px;
      }
      tooltip label {
        color: @text;
        padding: 2px 0;
      }

      /* ── 所有模块通用样式 ── */
      #workspaces,
      #window,
      #clock,
      #network,
      #cpu,
      #memory,
      #bluetooth,
      #keyboard-state,
      #battery,
      #tray {
        margin: 5px 6px;
        padding: 0 15px;
        background: rgba(49, 50, 68, 0.72);
        color: @text;
        border-radius: 20px;
        box-shadow: 0px 2px 4px 2px rgba(0, 0, 0, 0.28);
        transition: all 0.25s ease;
      }

      #workspaces {
        margin-left: 0;
        padding-left: 5px;
        padding-right: 5px;
      }
      #tray {
        padding-left: 10px;
        padding-right: 10px;
      }

      /* ══════════════════════════════════════════════════════
         工作区按钮
         ══════════════════════════════════════════════════════ */
      #workspaces button {
        all: unset;
        min-width: 36px;
        padding: 0 8px;
        margin: 4px 1px;
        border-radius: 14px;
        color: @subtext0;
        background: transparent;
        transition: all 0.25s ease;
      }

      /* 悬停: 轻微提亮 */
      #workspaces button:hover {
        background: rgba(69, 71, 90, 0.50);
        color: @subtext1;
        box-shadow: 0px 0px 8px rgba(203, 166, 247, 0.15);
      }

      /* 空工作区: 半透明 */
      #workspaces button.empty {
        color: @overlay0;
        opacity: 0.55;
      }
      #workspaces button.empty:hover {
        color: @overlay1;
        opacity: 0.8;
      }

      /* 活跃工作区: 醒目高亮 */
      #workspaces button.active {
        background: rgba(203, 166, 247, 0.22);
        color: @mauve;
        font-weight: 600;
        box-shadow: 0px 0px 10px rgba(203, 166, 247, 0.18);
      }

      /* 紧急工作区: 红色高亮 */
      #workspaces button.urgent {
        background: rgba(243, 139, 168, 0.25);
        color: @red;
      }

      /* ══════════════════════════════════════════════════════
         各模块主题色
         ══════════════════════════════════════════════════════ */

      /* 窗口标题: 正文色 */
      #window {
        color: @text;
        font-style: italic;
      }

      /* 时钟: 薰衣草色, 加粗 */
      #clock {
        color: @lavender;
        font-weight: 700;
        letter-spacing: 0.3px;
      }

      /* 网络: 水鸭色 */
      #network {
        color: @teal;
      }
      #network.disconnected {
        color: @red;
      }

      /* CPU: 蓝色 */
      #cpu {
        color: @blue;
      }
      #cpu.warning {
        color: @yellow;
      }
      #cpu.critical {
        color: @red;
      }

      /* 内存: 淡紫色 */
      #memory {
        color: @mauve;
      }
      #memory.warning {
        color: @yellow;
      }
      #memory.critical {
        color: @red;
      }

      /* 蓝牙: 宝蓝 */
      #bluetooth {
        color: @sapphire;
      }

      /* 键盘状态: 桃色 */
      #keyboard-state {
        color: @peach;
      }

      /* ══════════════════════════════════════════════════════
         电池状态色
         ══════════════════════════════════════════════════════ */
      #battery {
        color: @subtext1;
      }
      #battery.charging,
      #battery.plugged {
        color: @green;
      }
      #battery.full {
        color: @green;
      }
      #battery.warning:not(.charging) {
        color: @yellow;
      }
      /* 低电量: 红色 */
      #battery.critical:not(.charging) {
        color: @red;
      }

      /* ══════════════════════════════════════════════════════
         托盘图标
         ══════════════════════════════════════════════════════ */
      #tray > .passive {
        -gtk-icon-shadow: none;
      }
      /* 需注意的托盘项: 红色微光 */
      #tray > .needs-attention {
        background: rgba(243, 139, 168, 0.22);
        border-radius: 8px;
      }
    '';
  };
}

