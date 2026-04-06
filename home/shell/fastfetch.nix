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
        separator = "  ";
      };
      modules = [
        "title"
        "separator"

        # --- --- --- 系统 --- --- ---
        {
          type = "os";
          key = "┌ 󱄅 OS";
        }
        {
          type = "host";
          key = "├ 󰌢 Host";
        }
        {
          type = "kernel";
          key = "├  Kernel";
        }
        {
          type = "uptime";
          key = "├ 󰔚 Uptime";
        }
        {
          type = "packages";
          key = "├ 󰏖 PKGs";
        }
        {
          type = "shell";
          key = "├ 󰈺 Shell";
        }
        {
          type = "display";
          key = "├ 󰍹 Display";
        }
        {
          type = "wm";
          key = "├  WM";
        }
        {
          type = "terminal";
          key = "└ 󰆍 Term";
        }

        "break"

        # --- --- --- 硬件 --- --- ---
        {
          type = "cpu";
          key = "┌ 󰻠 CPU";
          showPeCoreCount = true;
        }
        {
          type = "gpu";
          key = "├ 󰢮 GPU";
          detectionMethod = "pci";
        }
        {
          type = "memory";
          key = "├ 󰍛 RAM";
        }
        {
          type = "swap";
          key = "├ 󰾅 Swap";
        }
        {
          type = "disk";
          key = "├ 󰋊 Disk /";
          folders = "/";
        }
        {
          type = "disk";
          key = "└ 󰋊 Disk ~";
          folders = "/home";
        }

        "break"

        # --- --- --- 网络 --- --- ---
        {
          type = "localip";
          key = "┌ 󰩟 LAN";
          showIpv6 = false;
        }
        {
          type = "publicip";
          key = "└ 󰩠 WAN";
        }

        "break"
        "colors"
      ];
    };
  };
}
