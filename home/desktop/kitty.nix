{ config, pkgs, lib, ... }:

let
  # Linux 平台判断
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  # --- --- --- Kitty 终端模拟器配置 --- --- ---
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;

    # Shell 集成
    shellIntegration.enableFishIntegration = true;

    settings = lib.mkMerge [
      # --- 通用配置 (所有平台) ---
      {
        # ---------------------------------------------------------
        # 字体配置
        # ---------------------------------------------------------
        font_family = "JetBrainsMono Nerd Font Mono";
        font_size = lib.mkDefault 23.0; # 可由 per-host 模块覆盖为不同的字体大小
        # 不禁用编程连字
        disable_ligatures = "never";

        # ---------------------------------------------------------
        # 渲染与显示
        # ---------------------------------------------------------
        # 背景不透明度
        background_opacity = 0.7;
        # 长命令完成后发送桌面通知: 仅非焦点窗口, 且命令运行超过 10 秒 (需 shell integration)
        notify_on_cmd_finish = "unfocused 10";

        # ---------------------------------------------------------
        # 颜色与外观 (Catppuccin Mocha)
        # ---------------------------------------------------------
        # 手动声明色板: home-manager 的 themeFile 需从 GitHub (kitty-themes) 下载,
        # 弱网/离线环境不可用, 故直接写颜色 (kitty 使用 color0-15 数字命名色表)
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        selection_background = "#585b70";
        selection_foreground = "#cdd6f4";
        cursor = "none";        # none = 反色: 光标颜色随所在单元格的文本颜色变化
        # cursor_text_color 在 cursor = none 时被官方忽略, 故不设置
        url_color = "#f9e2af";
        # 基本色 (color0-7) 与亮色 (color8-15)
        color0 = "#45475a"; # black
        color1 = "#f38ba8"; # red
        color2 = "#a6e3a1"; # green
        color3 = "#f9e2af"; # yellow
        color4 = "#89b4fa"; # blue
        color5 = "#f5c2e7"; # magenta
        color6 = "#94e2d5"; # cyan
        color7 = "#bac2de"; # white
        color8 = "#585b70"; # bright black
        color9 = "#f38ba8"; # bright red
        color10 = "#a6e3a1"; # bright green
        color11 = "#f9e2af"; # bright yellow
        color12 = "#89b4fa"; # bright blue
        color13 = "#f5c2e7"; # bright magenta
        color14 = "#94e2d5"; # bright cyan
        color15 = "#a6adc8"; # bright white

        # ---------------------------------------------------------
        # 光标与鼠标
        # ---------------------------------------------------------
        cursor_shape = "block";
        # 闪烁间隔 0.5 秒, ease-in-out 缓动实现平滑过渡 (0 = 禁用, 负值 = 系统默认)。
        # 注: 历史上 easing + background_opacity < 1 有动画 bug (kitty#8401),
        # 已于 0.39.1 修复, 当前版本 (0.48.x) 可放心使用
        cursor_blink_interval = "0.5 ease-in-out";
        # 键盘闲置后永不停闪烁 (默认 15 秒后停止, 这是"闪烁不生效"的根源)
        cursor_stop_blinking_after = 0;
        mouse_hide_wait = -1; # 打字时立即隐藏鼠标指针
        # 光标拖尾特效:
        # 光标在某位置停留超过指定时间(ms)后移动才触发拖尾动画
        cursor_trail = 1;
        # 衰减时间 (最快/最慢, 秒) 与启动阈值 (最小移动格数):
        cursor_trail_decay = "0.1 0.4";
        cursor_trail_start_threshold = 0;
        # 拖尾颜色默认跟随光标颜色 (cursor_trail_color = none), 配合 cursor = none
        # 反色效果, 拖尾即随光标所在字符的颜色变化

        # ---------------------------------------------------------
        # 终端行为与兼容性
        # ---------------------------------------------------------
        scrollback_lines = 100000; # 回滚缓冲上限
        shell = "${pkgs.fish}/bin/fish"; # 启动时直接进入 fish shell
        # 标签页栏: 位置与风格
        tab_bar_edge = "top";        # 标签页栏置于顶部
        tab_bar_style = "powerline"; # Powerline 风格 (可选: fade / slant / separator / powerline / custom / hidden)
        # 标签页栏配色
        active_tab_background = "#89b4fa";   # 活动标签: 蓝
        active_tab_foreground = "#1e1e2e";   # 活动标签文字: 深色
        active_tab_font_style = "bold";      # 活动标签加粗
        inactive_tab_background = "#313244"; # 非活动标签: surface0
        inactive_tab_foreground = "#a6adc8"; # 非活动标签文字: subtext1
        inactive_tab_font_style = "normal";

        # ---------------------------------------------------------
        # 窗口管理
        # ---------------------------------------------------------
        # 垂直 5, 水平 7 (对应 ghostty 的 padding-y=5, padding-x=7)
        window_padding_width = "5 7";
        # niri 平铺 WM 下隐藏标题栏 (对应 ghostty window-decoration = false / alacritty decorations = None)
        hide_window_decorations = "titlebar-only";
        # 注: ghostty 的 quit-after-last-window-closed 在 kitty 无对应选项
        # (非 macOS 平台关闭最后一个窗口即退出, 仅 macOS 有 macos_quit_when_last_window_closed)

        # ---------------------------------------------------------
        # 窗口分割线 (边框)
        # ---------------------------------------------------------
        # 与标签栏配色一致: 活动窗口用 Mocha 蓝, 非活动用 surface0
        # (默认 active 为光标色、inactive 为背景自动变体, 与主题不协调)
        active_border_color = "#89b4fa";   # 活动窗口分割线: 蓝
        inactive_border_color = "#313244"; # 非活动窗口分割线: surface0

        # ---------------------------------------------------------
        # 窗口布局
        # ---------------------------------------------------------
        # splits 布局设为默认 (第一项即默认布局)
        # launch --location=vsplit/hsplit 仅在 splits 布局下生效。
        # 布局名: splits / tall / stack / grid / fat / horizontal / vertical
        enabled_layouts = "splits,tall,stack,grid,fat,horizontal,vertical";

        # ---------------------------------------------------------
        # URL 提示
        # ---------------------------------------------------------
        # detect_urls 默认开启, open_url_with_hints 默认绑定 ctrl+shift+e, 无需额外配置
      }

      # --- Linux 专有配置 ---
      (lib.mkIf isLinux {
        # 背景模糊 (Wayland 合成器需支持 ext-background-effect, niri >= 26.04)
        # 仅当 background_opacity < 1 时生效; 整数为模糊半径, 64 以内性能良好
        background_blur = 8;
      })
    ];

    keybindings = {
      # --- 窗口管理 ---
      "ctrl+shift+n" = "new_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+f" = "toggle_fullscreen";
      "ctrl+shift+m" = "toggle_maximized";
      "ctrl+shift+q" = "quit";

      # --- 字体大小 ---
      "ctrl+shift+equal" = "change_font_size all +1.5"; # kitty 中 "+" 键写作 equal/plus
      "ctrl+shift+minus" = "change_font_size all -1.5";
      "ctrl+shift+0" = "change_font_size all 0"; # 重置为配置字号

      # --- 滚动控制 ---
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";

      # --- 清屏 ---
      # 覆盖 kitty 默认的 next_layout 绑定, 与 ghostty 的 ctrl+shift+l 清屏保持一致
      "ctrl+shift+l" = "clear_terminal clear active";

      # --- 剪贴板操作 ---
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      # 注: kitty 默认 ctrl+shift+p 为 kitten 菜单前缀, 保留默认, 不覆盖为粘贴

      # --- 命令提示符跳转 (需 shell integration) ---
      "ctrl+shift+i" = "scroll_to_prompt 1"; # 下一个提示符
      "ctrl+shift+o" = "scroll_to_prompt -1"; # 上一个提示符 (覆盖默认的 pass_selection_to_program)

      # --- 配置重载 ---
      # 覆盖 kitty 默认的 start_resizing_window 绑定, 与 ghostty 的 ctrl+shift+r 保持一致
      "ctrl+shift+r" = "load_config_file";

      # --- 回滚搜索 ---
      # 覆盖 kitty 默认的 paste_from_selection 绑定, 对应 ghostty 的 ctrl+shift+s 搜索回滚
      "ctrl+shift+s" = "search_scrollback";

      # ============================================================
      # tmux 兼容快捷键
      # kitty 中 window = tmux pane, tab = tmux window
      # ============================================================

      # --- 分屏 ---
      "alt+s>alt+h" = "combine : launch --cwd=current --location=vsplit : layout_action rotate 180"; # 左分屏
      "alt+s>alt+l" = "launch --cwd=current --location=vsplit"; # 右分屏
      "alt+s>alt+k" = "combine : launch --cwd=current --location=hsplit : layout_action rotate 180"; # 上分屏
      "alt+s>alt+j" = "launch --cwd=current --location=hsplit"; # 下分屏

      # --- 焦点切换 ---
      "alt+h" = "neighboring_window left";
      "alt+l" = "neighboring_window right";
      "alt+k" = "neighboring_window up";
      "alt+j" = "neighboring_window down";

      # --- 窗口交换 ---
      # kitty 的 move_window 支持四个方向 (上下左右皆可交换)
      "alt+shift+h" = "move_window left"; # 与左侧窗口交换
      "alt+shift+l" = "move_window right"; # 与右侧窗口交换
      "alt+shift+k" = "move_window up"; # 与上方窗口交换
      "alt+shift+j" = "move_window down"; # 与下方窗口交换

      # --- 调整窗口尺寸 ---
      # kitty 的 resize_window 是调整当前窗口大小 (等价于移动分割线);
      # 无 shift = 水平方向, 有 shift = 垂直方向; equal 增大, minus 减小
      "alt+equal" = "resize_window wider"; # 水平增大
      "alt+minus" = "resize_window narrower"; # 水平减小
      "alt+shift+equal" = "resize_window taller"; # 垂直增大
      "alt+shift+minus" = "resize_window shorter"; # 垂直减小

      # --- 关闭 / 新建 / 切换 tab ---
      "alt+x" = "close_window"; # 关闭当前窗口
      "alt+w" = "new_tab_with_cwd"; # 新开标签页并继承 cwd
      "alt+shift+q" = "close_tab"; # 关闭当前标签页
      "alt+p" = "previous_tab"; # 上一个标签页
      "alt+n" = "next_tab"; # 下一个标签页
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";
      "alt+6" = "goto_tab 6";
      "alt+7" = "goto_tab 7";
      "alt+8" = "goto_tab 8";
      "alt+9" = "goto_tab 9";
      "alt+0" = "goto_tab 0"; # 0/负数 = 上一个标签页

      # --- 最大化 / 布局 ---
      "alt+f" = "toggle_layout stack"; # 最大化/还原当前窗口
      "alt+shift+/" = "next_layout"; # 轮换布局

      # --- 重命名 ---
      "alt+r" = "set_window_title"; # 重命名当前窗口 (tmux M-r rename-pane)
      "alt+shift+r" = "set_tab_title"; # 重命名当前标签页 (tmux M-R rename-window)
    };
  };
}
