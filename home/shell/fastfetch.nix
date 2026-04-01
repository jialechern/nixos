{ config, pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos"; 
        padding = {
          right = 2;
          top = 1;
        };
      };
      display = {
        size = {
          binaryPrefix = "si";
        };
        color = {
          keys = "magenta";
          output = "white";
        };
        separator = "  ";
      };
      modules = [
        "title"
        "separator"
        {
          type = "os";
          key = "󱄅 OS";
        }
        {
          type = "host";
          key = "󰌢 Host";
        }
        {
          type = "kernel";
          key = " Kernel";
        }
        {
          type = "uptime";
          key = "󰔚 Uptime";
        }
        {
          type = "packages";
          key = "󰏖 PKGs";
        }
        {
          type = "shell";
          key = "󰈺 Shell";
        }
        {
          type = "display";
          key = "󰍹 Display";
        }
        {
          type = "wm";
          key = " WM";
        }
        {
          type = "terminal";
          key = "󰆍 Term";
        }
        "break"
        
        # --- 硬件实时监控 ---
        {
          type = "cpu";
          key = "󰻠 CPU";
          showPeCoreCount = true;
        }
        {
          type = "gpu";
          key = "󰢮 GPU";
        }
        {
          type = "memory";
          key = "󰍛 RAM";
        }
        {
          type = "swap";
          key = "󰾅 SWAP";
        }
        {
          type = "disk";
          key = "󰋊 Disk (Home)";
          folders = "/home"; 
        }
        "break"

        # --- 网络与环境 ---
        {
          type = "localip";
          key = "󰩟 LAN";
        }
        {
          type = "publicip";
          key = "󰩠 WAN";
        }
        "break"

        # --- 媒体与色彩 ---
        {
          type = "datetime";
          key = "󰃭 Date";
          format = "{1}-{3}-{11}";
        }
        "player"
        "media"
        "break"
        "colors"
      ];
    };
  };
}
