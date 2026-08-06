{ config, pkgs, lib, ... }:

let
  # Linux 平台判断
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  # 光标拖尾着色器文件名 (与 scripts/ 目录下的文件名一致)
  cursorSmearShader = "cursor_smear.glsl";
in
{
  # --- --- --- Ghostty 终端声明式配置 --- --- ---
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;

    # 清除 Ghostty 默认快捷键, 仅保留显式声明的绑定
    clearDefaultKeybinds = true;

    # bat 语法高亮 (用于 `bat` 查看配置文件时高亮显示)
    installBatSyntax = true;

    # Shell 集成自动加载 (bash / zsh / fish)
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = lib.mkMerge [
      # --- 通用配置 (所有平台) ---
      {
        # ---------------------------------------------------------
        # 字体配置
        # ---------------------------------------------------------
        "font-family" = "JetBrainsMono Nerd Font Mono";
        "font-style" = "default";
        "font-style-bold" = "default";
        "font-style-italic" = "default";
        "font-style-bold-italic" = "default";
        # 当字体缺失某种样式时, 允许 Ghostty 自动合成斜体或粗体
        "font-synthetic-style" = "bold,italic,bold-italic";
        # 启用现代编程连字特性 (calt = 上下文替代, liga = 标准连字, dlig = 自由连字)
        "font-feature" = "+calt,+liga,+dlig";
        "font-size" = 27;


        # ---------------------------------------------------------
        # 渲染与显示
        # ---------------------------------------------------------
        "font-shaping-break" = "cursor";
        # 线性 alpha 混合校正, 提升半透明文字的清晰度
        "alpha-blending" = "linear-corrected";
        "freetype-load-flags" = "hinting,no-force-autohint,no-monochrome,autohint";
        # 垂直同步, 消除快速滚动时的撕裂感
        "window-vsync" = true;
        # srgb 色彩空间以获得最准确的颜色表现
        "window-colorspace" = "srgb";
        # 使用原生 GTK 标题栏
        "gtk-titlebar" = true;
        # 桌面通知
        "desktop-notifications" = true;
        # 长命令完成后发送桌面通知 (仅非焦点窗口)
        "notify-on-command-finish" = "unfocused";
        # 运行超过 10 秒的命令才触发通知, 避免干扰
        "notify-on-command-finish-after" = "10s";
        # 通知方式: 响铃 + 桌面通知 (默认只有响铃, 需显式开启 notify)
        "notify-on-command-finish-action" = "bell,notify";

        # ---------------------------------------------------------
        # 颜色与外观
        # ---------------------------------------------------------
        "theme" = "Catppuccin Mocha";
        "background-opacity" = 0.3;
        # 1.4 (2026-09) 支持 ext-background-effect 后可直接 background-blur = true
        "background-blur" = false;
        "unfocused-split-opacity" = 1.0;
        # 使 Neovim / Tmux 底部状态栏也继承透明背景
        # "background-opacity-cells" = true;

        # ---------------------------------------------------------
        # 光标与鼠标
        # ---------------------------------------------------------
        "cursor-style" = "block";
        "cursor-opacity" = 1;
        "cursor-style-blink" = false;
        # 点击移动光标, 向支持的应用发送点击序列
        "cursor-click-to-move" = true;
        # 输入时隐藏鼠标指针
        "mouse-hide-while-typing" = true;
        # 光标拖尾特效着色器
        "custom-shader" = "${config.xdg.configHome}/ghostty/${cursorSmearShader}";
        "custom-shader-animation" = true;

        # ---------------------------------------------------------
        # 终端行为与兼容性
        # ---------------------------------------------------------
        "scrollback-limit" = 10000000;
        # "scrollbar" = true;               # 1.3.0 原生滚动条
        "scroll-to-bottom" = "keystroke,output"; # 有新输出时自动滚到底部 (1.3.0)
        "link-url" = true;
        "link-previews" = true;
        "clipboard-write" = "allow";
        "clipboard-trim-trailing-spaces" = true;
        "image-storage-limit" = 320000000;
        # 启动时直接进入 fish shell
        "command" = "${pkgs.fish}/bin/fish";
        "shell-integration" = "detect";
        "shell-integration-features" = "cursor,no-sudo,title,path,ssh-env,ssh-terminfo";
        "window-show-tab-bar" = "auto";
        # 标签页栏置于底部
        "gtk-tabs-location" = "bottom";
        # 宽标签页, 使标签页在栏中均匀分布
        "gtk-wide-tabs" = true;
        "window-new-tab-position" = "current";

        # ---------------------------------------------------------
        # 窗口管理
        # ---------------------------------------------------------
        "window-padding-x" = 7;
        "window-padding-y" = 5;
        "window-inherit-working-directory" = true;
        "window-decoration" = false;
        "quit-after-last-window-closed" = true;

        # ---------------------------------------------------------
        # 快速终端 (Quick Terminal)
        # ---------------------------------------------------------
        "gtk-quick-terminal-layer" = "overlay";   # 悬浮在顶层
        "gtk-quick-terminal-namespace" = "ghostty:quick-terminal";

        "keybind" = [
          # --- 窗口管理 ---
          "ctrl+shift+n=new_window"
          "ctrl+shift+f=toggle_fullscreen"
          "ctrl+shift+m=toggle_maximize"

          # --- 退出 / 关闭 ---
          "ctrl+shift+q=quit"
          "ctrl+shift+w=close_surface"

          # --- 字体大小 ---
          "ctrl+shift+==increase_font_size:1.5"
          "ctrl+shift+-=decrease_font_size:1.5"
          "ctrl+shift+0=reset_font_size"

          # --- 滚动控制 ---
          "ctrl+shift+[=scroll_to_top"
          "ctrl+shift+]=scroll_to_bottom"
          "ctrl+shift+,=scroll_page_up"
          "ctrl+shift+.=scroll_page_down"

          # --- 清屏 ---
          "ctrl+shift+l=clear_screen"

          # --- 剪贴板操作 ---
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+y=copy_to_clipboard"
          "alt+shift+y=copy_title_to_clipboard"
          "alt+shift+c=copy_url_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"
          "ctrl+shift+p=paste_from_clipboard"
          "alt+shift+p=paste_from_selection"

          # --- 命令提示符跳转 ---
          "ctrl+shift+i=jump_to_prompt:1"
          "ctrl+shift+o=jump_to_prompt:-1"

          # --- 配置重载 ---
          "ctrl+shift+r=reload_config"

          # --- 命令面板 ---
          "ctrl+alt+p=toggle_command_palette"

          # --- 浮动终端 (Ghostty 专有) ---
          "ctrl+shift+t=toggle_quick_terminal"

          # --- 回滚搜索 (1.3.0) ---
          "ctrl+shift+s=start_search"
          "ctrl+shift+z=search_selection"      # 搜索当前选区 (类似 vim *)
          # "enter=navigate_search:next"
          # "shift+enter=navigate_search:previous"

          # --- 透明度 ---
          "alt+shift+o=toggle_background_opacity"  # 一键切换透明/不透明
        ];
      }

      # --- Linux 专有配置 ---
      (lib.mkIf isLinux {
        # 单实例模式节省内存
        "linux-cgroup" = "single-instance";

        "keybind" = [
          # 切换窗口装饰 (标题栏 / 边框) 显隐
          "ctrl+alt+shift+[=toggle_window_decorations"
          # # 显示屏幕虚拟键盘
          # "ctrl+alt+shift+k=show_on_screen_keyboard"
          # # 标签页缩略图概览 (与 niri 窗口概览冲突, 已禁用)
          # "alt+t>alt+p=toggle_tab_overview"
          # # 重命名当前分屏 / surface
          # "alt+s>alt+r=prompt_surface_title"
        ];
      })
    ];
  };

  # --- --- --- 光标拖尾特效着色器 --- --- ---
  # 构建时读取 shader 内容并嵌入
  home.file."${config.xdg.configHome}/ghostty/${cursorSmearShader}".text =
    builtins.readFile ./ghostty/${cursorSmearShader};
}
