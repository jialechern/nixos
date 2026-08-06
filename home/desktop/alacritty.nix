{ config, pkgs, lib, ... }:

{
  # --- --- --- Alacritty 终端模拟器配置 --- --- ---
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    theme = "catppuccin_mocha";  # Catppuccin Mocha 主题

    settings = {
      # --- --- --- IPC (守护进程模式) --- --- ---
      # ipc_socket 默认开启, 可在 niri 快捷键/脚本中使用:
      #   alacritty msg create-window --working-directory <目录>   # 按指定目录开新窗口
      #   alacritty msg config --load <file>                       # 运行时加载配置
      #   alacritty msg get-config                                 # 查看生效配置 (0.16+)
      # 文档: https://alacritty.org/cmd-alacritty-msg.html

      # --- --- --- 终端 --- --- ---
      terminal.shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [];
      };
      terminal.osc52 = "CopyPaste";     # SSH 远程会话可读写本地剪贴板 (个人桌面机可接受)

      # --- --- --- 光标 --- --- ---
      cursor = {
        style = {
          shape = "Beam";             # I 形光标
          blinking = "Off";           # 禁止闪烁
        };
        vi_mode_style = {
          shape = "Block";            # Vi 模式下使用块状光标
          blinking = "Off";
        };
      };

      # --- --- --- 选择 --- --- ---
      selection.semantic_escape_chars = ",│`|:\"'()[]{}<>\t";
      # 去除了 Alacritty 默认值中括号周围的空格, 以适配中文内容

      # --- --- --- 颜色 --- --- ---
      # colors.transparent_background_colors = true; # 所有单元格背景随 opacity 透明, 透明终端效果更完整

      # --- --- --- 回滚 --- --- ---
      scrolling.history = 100000;       # 回滚缓冲上限 (默认 10000, 上限 100000)

      # --- --- --- 鼠标 --- --- ---
      mouse = {
        hide_when_typing = true;        # 打字时自动隐藏鼠标指针
        bindings = [
          # Shift+滚轮: 逐行滚动 (Alacritty 0.17+, 若锁定版本更旧需移除)
          { mouse = "WheelUp"; mods = "Shift"; action = "ScrollLineUp"; }
          { mouse = "WheelDown"; mods = "Shift"; action = "ScrollLineDown"; }
        ];
      };

      # --- --- --- 字体 --- --- ---
      font = {
        size = lib.mkDefault 23.0;    # 可由 per-host 模块覆盖为不同的字体大小
        normal = {
          family = "JetBrainsMono Nerd Font Mono";
        };
      };

      # --- --- --- 窗口 --- --- ---
      window = {
        padding = { x = 13; y = 7; }; # 内边距
        decorations = "None";         # niri 平铺 WM 下隐藏标题栏
        opacity = 0.3;                # 30% 不透明度(即 70% 透明)
        blur = true;                  # 背景模糊 (需 winit 支持 ext-background-effect, niri >= 26.04)
      };

      # --- --- --- URL 提示 --- --- ---
      hints = {
        alphabet = "jfkdls;ahgurieowpq";
        enabled = [
          {
            command = "xdg-open";
            hyperlinks = true;
            post_processing = true;
            persist = false;
            mouse.enabled = true;
            binding = { key = "O"; mods = "Control|Shift"; };
            regex = ''(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^\u0000-\u001F\u007F-\u009F<>\"\\s{-}\\^⟨⟩`\\\\]+'';
          }
          # 复制 URL 到剪贴板 (Ctrl+Shift+Y)
          {
            action = "Copy";
            hyperlinks = true;
            post_processing = true;
            persist = false;
            mouse.enabled = true;
            binding = { key = "Y"; mods = "Control|Shift"; };
            regex = ''(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^\u0000-\u001F\u007F-\u009F<>\"\\s{-}\\^⟨⟩`\\\\]+'';
          }
        ];
      };

      # --- --- --- 键盘绑定 --- --- ---
      keyboard.bindings = [
        # --- 窗口管理 ---
        { key = "Return"; mods = "Control|Shift"; action = "SpawnNewInstance"; }
        { key = "N"; mods = "Control|Shift"; action = "CreateNewWindow"; }
        { key = "F"; mods = "Control|Shift"; action = "ToggleFullscreen"; }
        { key = "M"; mods = "Control|Shift"; action = "ToggleMaximized"; }
        # # Minimize 在 niri 环境下无效
        # { key = "H"; mods = "Control|Shift"; action = "Minimize"; }
        { key = "Q"; mods = "Control|Shift"; action = "Quit"; }

        # --- 字体大小 ---
        { key = "="; mods = "Control"; action = "IncreaseFontSize"; }
        { key = "-"; mods = "Control"; action = "DecreaseFontSize"; }
        { key = "0"; mods = "Control"; action = "ResetFontSize"; }

        # --- 滚动 ---
        { key = "Home"; mods = "Control|Shift"; action = "ScrollToTop"; }
        { key = "End"; mods = "Control|Shift"; action = "ScrollToBottom"; }
        { key = "PageUp"; mods = "Control|Shift"; action = "ScrollPageUp"; }
        { key = "PageDown"; mods = "Control|Shift"; action = "ScrollPageDown"; }

        # --- 复制粘贴 ---
        { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        { key = "V"; mods = "Control|Shift"; action = "Paste"; }

        # --- Vi 模式切换 ---
        { key = "Escape"; mods = "Control"; mode = "~Vi|~Search"; action = "ToggleViMode"; }

        # --- Vi 模式: 移动光标 ---
        { key = "H"; mods = "None"; mode = "Vi"; action = "Left"; }
        { key = "J"; mods = "None"; mode = "Vi"; action = "Down"; }
        { key = "K"; mods = "None"; mode = "Vi"; action = "Up"; }
        { key = "L"; mods = "None"; mode = "Vi"; action = "Right"; }
        { key = "W"; mods = "None"; mode = "Vi"; action = "WordRight"; }
        { key = "B"; mods = "None"; mode = "Vi"; action = "WordLeft"; }
        { key = "E"; mods = "None"; mode = "Vi"; action = "WordRightEnd"; }
        { key = "0"; mods = "None"; mode = "Vi"; action = "First"; }
        { key = "$"; mods = "Shift"; mode = "Vi"; action = "Last"; }
        { key = "^"; mods = "Shift"; mode = "Vi"; action = "FirstOccupied"; }
        { key = "%"; mods = "Shift"; mode = "Vi"; action = "Bracket"; }

        # --- Vi 模式: 滚动 ---
        { key = "G"; mods = "Shift"; mode = "Vi"; action = "ScrollToBottom"; }
        { key = "Home"; mods = "None"; mode = "Vi"; action = "ScrollToTop"; }
        { key = "K"; mods = "Shift"; mode = "Vi"; action = "ScrollHalfPageUp"; }
        { key = "J"; mods = "Shift"; mode = "Vi"; action = "ScrollHalfPageDown"; }
        { key = "PageUp"; mods = "None"; mode = "Vi"; action = "ScrollPageUp"; }
        { key = "PageDown"; mods = "None"; mode = "Vi"; action = "ScrollPageDown"; }
        { key = "Z"; mods = "None"; mode = "Vi"; action = "CenterAroundViCursor"; }
        { key = "Z"; mods = "Control"; mode = "Vi"; action = "Middle"; }

        # --- Vi 模式: 选择 ---
        { key = "V"; mods = "Shift"; mode = "Vi"; action = "ToggleLineSelection"; }
        { key = "V"; mods = "Control"; mode = "Vi"; action = "ToggleBlockSelection"; }
        { key = "V"; mods = "None"; mode = "Vi"; action = "ToggleNormalSelection"; }

        # --- Vi 模式: 搜索 ---
        { key = "/"; mods = "None"; mode = "Vi"; action = "SearchForward"; }
        { key = "?"; mods = "Shift"; mode = "Vi"; action = "SearchBackward"; }
        { key = "N"; mods = "None"; mode = "Vi"; action = "SearchNext"; }
        { key = "N"; mods = "Shift"; mode = "Vi"; action = "SearchPrevious"; }

        # --- Vi 模式: 复制粘贴 ---
        { key = "Y"; mods = "None"; mode = "Vi"; action = "Copy"; }
        { key = "Y"; mods = "Shift"; mode = "Vi"; action = "Copy"; }
        { key = "P"; mods = "None"; mode = "Vi"; action = "Paste"; }
        { key = "P"; mods = "Shift"; mode = "Vi"; action = "Paste"; }

        # --- Vi 模式: 行内搜索 ---
        { key = "F"; mods = "None"; mode = "Vi"; action = "InlineSearchForward"; }
        { key = "F"; mods = "Shift"; mode = "Vi"; action = "InlineSearchBackward"; }

        # --- Vi 模式: 打开 URL ---
        { key = "O"; mods = "Control"; mode = "Vi"; action = "Open"; }
      ];

      # --- --- --- 环境变量(按需取消注释) --- --- ---
      env = {
        # WINIT_X11_SCALE_FACTOR = "1.0";
      };
    };
  };
}
