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
        exclusive = true;
        passthrough = false;

        # 固定中心: clock 严格居中而不随左右模块宽度变化偏移
        "fixed-center" = true;
        height = 42;
        spacing = 0;

        # 外边距使顶栏不贴屏幕边缘
        "margin-top" = 6;
        "margin-left" = 12;
        "margin-right" = 12;
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
        # 系统托盘
        tray = {
          "icon-size" = 20;
          spacing = 10;
        };

        # 时钟
        clock = {
          interval = 1;
          format = " {:%Y-%m-%d %H:%M:%S}";
          # 左键点击切换为简短日期格式
          "format-alt" = "{:%m-%d %H:%M}";
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        # 工作区
        "niri/workspaces" = {
          format = "{icon}";
          "format-icons" = {
            # 默认/非活跃工作区图标
            "default" = "";

            # 活跃(有焦点窗口)工作区图标
            "active" = "";
          };

          # 所有显示器上显示全部工作区
          "all-outputs" = true;
        };
        # 当前窗口标题
        "niri/window" = {
          format = "{title}";

          # 最大显示长度, 超出省略
          "max-length" = 60;

          # 重写规则: 精简常见应用的冗余标题
          rewrite = {
            "(.*) — Mozilla Firefox" = "󰈹 $1";
            "(.*) - Chromium" = "󰊯 $1";
            "(.*) - Google Chrome" = "󰊯 $1";
            "(.*) - Visual Studio Code" = "󰨞 $1";
          };
        };
        
        # 网络
        network = {
          interval = 5;
          "format-wifi" = " {essid}";
          "format-ethernet" = "󰈀 {ipaddr}";
          "format-disconnected" = "⚠ 断连";
          "tooltip-format" = "{ifname} via {gwaddr} ";
          "tooltip-format-wifi" = "{essid} ({signaldBm}dBm) \nIP: {ipaddr}\n网关: {gwaddr}";
          "tooltip-format-ethernet" = "{ifname} \nIP: {ipaddr}";
          "tooltip-format-disconnected" = "网络已断开";
          "on-click" = "nm-connection-editor";
        };

        # CPU
        cpu = {
          interval = 2;
          format = " {usage}%";
          # 负载阈值, 自动添加 .warning / .critical CSS 类
          states = {
            warning = 70;
            critical = 90;
          };
        };

        # 内存
        memory = {
          interval = 5;
          format = " {percentage}%";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        # 蓝牙
        bluetooth = {
          format = " 关闭";
          "format-connected" = " {device_alias}";
          # 连接设备含电量时显示电量百分比
          "format-connected-battery" = " {device_alias} ⚡{device_battery_percentage}%";
          "tooltip-format" = "蓝牙适配器: {controller_alias}\n已连接: {num_connections} 个设备";
          "tooltip-format-connected" = "{controller_alias}\n\n已连接设备:\n{device_enumerate}";
          "tooltip-format-enumerate-connected" = "   {device_alias}";
          "tooltip-format-enumerate-connected-battery" = "   {device_alias} 电量 {device_battery_percentage}%";
          "on-click" = "overskride";
        };

        # 键盘状态指示
        "keyboard-state" = {
          numlock = true;
          capslock = true;

          # 分键显示写法(Waybar 0.10+)
          format = {
            numlock = "N {icon}";
            capslock = "C {icon}";
          };

          "format-icons" = {
            locked = "";
            unlocked = "";
          };
        };

        # 电池
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };

          format = " {capacity}%";
          "format-charging" = " {capacity}%";
          "format-plugged" = " {capacity}%";

          # 电量充满时显示
          "format-full" = " 满电";

          # 右键切换为时间预估格式
          "format-alt" = "{icon} {time}";
          "format-icons" = [ "" "" "" "" "" ];
          "tooltip-format" = "剩余时间: {timeTo}";
        };
      };
    };

    style = ''
      /* ── Nord 配色 ── */
      @define-color nord0  #2e3440;
      @define-color nord1  #3b4252;
      @define-color nord2  #434c5e;
      @define-color nord3  #4c566a;
      @define-color nord4  #d8dee9;
      @define-color nord5  #e5e9f0;
      @define-color nord6  #eceff4;
      @define-color nord7  #8fbcbb;
      @define-color nord8  #88c0d0;
      @define-color nord9  #81a1c1;
      @define-color nord10 #5e81ac;
      * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK SC", sans-serif;
        font-size: 14px;
        border: none;
        min-height: 0;
      }
      /* ── 顶栏本体: 透明背景 + 底部阴影 ── */
      window#waybar {
        background: transparent;
        color: @nord4;
        /* 阴影参数与 niri layer-rule 保持一致（y=5, spread=5, softness=7, #00000077） */
        box-shadow: 0px 5px 7px 5px rgba(0, 0, 0, 0.47);
        /* 平滑过渡 */
        transition-property: background-color, box-shadow;
        transition-duration: 0.3s;
      }
      /* 无窗口时隐藏窗口标题模块 */
      window#waybar.empty #window {
        background: transparent;
        box-shadow: none;
        padding: 0;
        margin: 0;
      }
      /* ── 工具提示 ── */
      tooltip {
        background: rgba(46, 52, 64, 0.96);
        border: 1px solid rgba(76, 86, 106, 0.75);
        border-radius: 14px;
      }
      tooltip label {
        color: @nord4;
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
        margin: 4px 6px;
        padding: 0 14px;
        background: rgba(59, 66, 82, 0.68);
        color: @nord4;
        border-radius: 16px;
        /* 模块微阴影，增加立体感 */
        box-shadow: 0px 2px 3px 2px rgba(0, 0, 0, 0.25);
        /* 平滑悬停过渡 */
        transition: all 0.2s ease;
      }
      #workspaces {
        margin-left: 0;
      }
      #tray {
        padding-left: 10px;
        padding-right: 10px;
      }
      /* ── 工作区按钮 ── */
      #workspaces button {
        all: unset;
        min-width: 32px;
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 12px;
        color: @nord5;
        background: transparent;
        transition: all 0.2s ease;
      }
      #workspaces button:hover {
        background: rgba(76, 86, 106, 0.42);
        color: @nord6;
      }
      #workspaces button.focused,
      #workspaces button.active {
        background: rgba(94, 129, 172, 0.34);
        color: @nord6;
      }
      #workspaces button.urgent {
        background: rgba(191, 97, 106, 0.36);
        color: @nord6;
      }
      /* ── 各模块主题色 ── */
      #window {
        color: @nord4;
      }
      #clock {
        color: @nord8;
        font-weight: 600;
        letter-spacing: 0.2px;
      }
      #network {
        color: @nord7;
      }
      #network.disconnected {
        color: #bf616a;
      }
      #cpu {
        color: @nord9;
      }
      #cpu.warning {
        color: #ebcb8b;
      }
      #cpu.critical {
        color: #bf616a;
      }
      #memory {
        color: @nord10;
      }
      #memory.warning {
        color: #ebcb8b;
      }
      #memory.critical {
        color: #bf616a;
      }
      #bluetooth {
        color: @nord7;
      }
      #keyboard-state {
        color: @nord5;
      }
      /* ── 电池状态色 ── */
      #battery {
        color: @nord5;
      }
      #battery.charging,
      #battery.plugged {
        color: #a3be8c;
      }
      #battery.full {
        color: #a3be8c;
      }
      #battery.warning:not(.charging) {
        color: #ebcb8b;
      }
      #battery.critical:not(.charging) {
        color: #bf616a;
        /* 低电量闪烁 */
        animation-name: blink;
        animation-duration: 1s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }
      @keyframes blink {
        to {
          color: @nord4;
        }
      }
      /* ── 托盘图标 ── */
      #tray > .passive {
        -gtk-icon-shadow: none;
      }
      #tray > .needs-attention {
        background: rgba(191, 97, 106, 0.20);
      }
    '';
  };
}
