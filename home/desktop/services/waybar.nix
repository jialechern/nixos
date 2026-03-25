{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";

        # 让窗口被“挤下来”，而不是顶栏压在窗口上面
        mode = "dock";
        exclusive = true;
        passthrough = false;
        "gtk-layer-shell" = true;

        height = 42;
        spacing = 0;

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

        ipc = true;
        id = "bar-0";

        tray = {
          "icon-size" = 20;
          spacing = 10;
        };

        clock = {
          interval = 1;
          format = " {:%Y-%m-%d %H:%M:%S}";
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        network = {
          interval = 5;
          "format-wifi" = "{essid} ({ipaddr})";
          "format-ethernet" = "󰈀 {ipaddr}";
          "format-disconnected" = "⚠ Disconnected";
          "tooltip-format" = "{ifname} via {gwaddr} ";
          "tooltip-format-wifi" = "{essid} ({signaldBm}dBm) \nIP: {ipaddr}\nGateway: {gwaddr}";
          "tooltip-format-ethernet" = "{ifname} \nIP: {ipaddr}";
          "on-click" = "nm-connection-editor";
        };

        cpu = {
          format = " {usage}%";
        };

        memory = {
          format = " {percentage}%";
        };

        bluetooth = {
          format = " {status}";
          "format-connected" = " {device_alias}";
          "on-click" = "overskride";
        };

        "keyboard-state" = {
          numlock = true;
          capslock = true;
          format = "{name} {icon}";
          "format-icons" = {
            locked = "";
            unlocked = "";
          };
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          "format-charging" = " {capacity}%";
          "format-plugged" = " {capacity}%";
          "format-alt" = "{icon} {time}";
          "format-icons" = [ "" "" "" "" "" ];
          "tooltip-format" = "{timeTo}";
        };
      };
    };

    style = ''
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

      window#waybar {
        background: transparent;
        color: @nord4;
      }

      tooltip {
        background: rgba(46, 52, 64, 0.96);
        border: 1px solid rgba(76, 86, 106, 0.75);
        border-radius: 14px;
      }

      tooltip label {
        color: @nord4;
      }

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
      }

      #workspaces {
        margin-left: 0;
      }

      #tray {
        padding-left: 10px;
        padding-right: 10px;
      }

      #workspaces button {
        all: unset;
        min-width: 32px;
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 12px;
        color: @nord5;
        background: transparent;
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

      #cpu {
        color: @nord9;
      }

      #memory {
        color: @nord10;
      }

      #bluetooth {
        color: @nord7;
      }

      #keyboard-state {
        color: @nord5;
      }

      #battery {
        color: @nord5;
      }

      #battery.charging,
      #battery.plugged {
        color: @nord7;
      }

      #battery.warning {
        color: #ebcb8b;
      }

      #battery.critical {
        color: #bf616a;
      }

      #tray > .passive {
        -gtk-icon-shadow: none;
      }

      #tray > .needs-attention {
        background: rgba(191, 97, 106, 0.20);
      }
    '';
  };
}
