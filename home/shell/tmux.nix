{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # --- --- --- 基本设置 --- --- ---
    prefix = "M-/";
    mouse = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;

    # --- --- --- Home Manager 声明式选项 --- --- ---
    historyLimit = 10000; # 回滚行数 (默认 2000)
    focusEvents = true; # 终端焦点事件透传
    clock24 = true; # 24 小时制
    aggressiveResize = true; # 窗口大小跟随最小 session
    newSession = true; # 无 session 时自动创建
    disableConfirmationPrompt = true; # 杀死 pane/window 时免确认
    secureSocket = true; # socket 存于 /run (Linux 默认值, 显式声明)
    sensibleOnTop = true; # sensible 插件前置, 可被 extraConfig 覆盖

    # --- --- --- 插件 --- --- ---
    plugins = with pkgs.tmuxPlugins; [
      # --- 持久化 ---
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'    # 恢复 nvim session
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'         # 每 15 分钟自动保存
        '';
      }

      # --- 主题 ---
      nord

      # --- 其它工具 ---
      fzf-tmux-url # fzf 模糊搜索并打开 pane 中的 URL/文件路径
      open # 用默认程序打开高亮内容
      extrakto # fzf 快速抓取 pane 中的文本 (路径、URL、单词等)

      # --- 系统剪贴板 ---
      yank

      # --- 状态栏 ---
      prefix-highlight # 按下 prefix 时状态栏高亮提示
    ];

    # --- --- --- 原生配置无法表达的部分 --- --- ---
    extraConfig = ''
      # ============================================================
      # 终端兼容性与色彩
      # ============================================================
      set -g allow-passthrough all
      set -as terminal-features 'tmux-256color:RGB'

      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'

      # ============================================================
      # 外观设置
      # ============================================================
      # 状态栏默认隐藏, M-m 切换显隐
      bind -n M-m if -F "#{==:#{status},on}" "set -g status off" "set -g status on" \; refresh-client -S
      set -g status off
      # pane 分割线颜色
      set -g pane-border-style "fg=black"
      set -g pane-active-border-style "fg=black"
      # pane 标题栏
      set -g pane-border-status top
      # 窗口被手动重命名后禁止 tmux 自动覆盖标题
      set -g allow-rename off
      # 只显示一个小标记, 而不是整块标题栏
      set -g pane-border-indicators colour

      # ============================================================
      # 窗口编号管理
      # ============================================================
      # 关闭窗口后自动重新编号
      set -g renumber-windows on
      # (pane-base-index 与 window-base-index 已由 baseIndex = 1 自动设置)

      # ============================================================
      # Session 管理
      # ============================================================
      # 选择 session
      bind -n M-s choose-session
      # 重命名 session
      bind -n M-S command-prompt -I "#S" "rename-session '%%'"

      # ============================================================
      # 通用快捷操作
      # ============================================================
      # 重新加载配置 (使用 Home Manager 管理的实际路径)
      bind M-r source-file ${config.home.homeDirectory}/.config/tmux/tmux.conf \; display-message "tmux config reloaded"
      # 重命名窗口
      bind -n M-R command-prompt -I "#W" "rename-window '%%'"
      # 重命名 pane
      bind -n M-r command-prompt -I "#P" "select-pane -T '%%'"
      # 最大化/还原当前 pane
      bind -n M-f resize-pane -Z
      # detach session
      bind -n M-d detach
      bind -n M-q detach
      # 关闭当前 pane
      bind -n M-x kill-pane
      # 显示 pane 编号并允许按数字跳转
      bind -n M-g display-panes
      # 大时钟显示
      bind -n M-t clock-mode

      # ============================================================
      # Window 管理
      # ============================================================
      # 取消默认切换方式
      unbind n
      unbind p
      # 窗口切换
      bind -nr M-p previous-window
      bind -nr M-n next-window
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9
      bind -n M-0 select-window -t 0   # 预留: baseIndex=1 时通常无 0 号窗口
      # 关闭窗口
      bind -n M-Q kill-window
      # 新建窗口
      bind -n M-c new-window
      # 轮换窗口编号
      bind-key -n M-- swap-window -t -1 \; previous-window
      bind-key -n M-= swap-window -t +1 \; next-window

      # ============================================================
      # Pane 管理
      # ============================================================
      # 分屏 (使用 prefix + 方向键)
      bind M-k split-window -vb -c "#{pane_current_path}"
      bind M-j split-window -v -c "#{pane_current_path}"
      bind M-h split-window -hb -c "#{pane_current_path}"
      bind M-l split-window -h -c "#{pane_current_path}"
      # 焦点切换 (Alt + h/j/k/l)
      bind -n M-h select-pane -L
      bind -n M-l select-pane -R
      bind -n M-k select-pane -U
      bind -n M-j select-pane -D
      # 挪动 pane 到指定窗口
      bind -n M-! join-pane -t :1
      bind -n M-@ join-pane -t :2
      bind -n M-# join-pane -t :3
      bind -n M-$ join-pane -t :4
      bind -n M-% join-pane -t :5
      bind -n M-^ join-pane -t :6
      bind -n M-& join-pane -t :7
      bind -n M-* join-pane -t :8
      bind -n M-( join-pane -t :9
      bind -n M-) join-pane -t :0
      # pane 交换位置
      bind -n M-] swap-pane -D
      bind -n M-[ swap-pane -U
      bind -n M-| next-layout
      # 挪动 pane 到相邻窗口并跳转
      bind -n M-P join-pane -t :-
      bind -n M-N join-pane -t :+
      # 以当前 pane 新建窗口
      bind -n M-F break-pane
      # 调整 pane 尺寸 (Alt + Shift + H/J/K/L)
      bind -n M-H resize-pane -L 1
      bind -n M-L resize-pane -R 1
      bind -n M-K resize-pane -U 1
      bind -n M-J resize-pane -D 1

      # ============================================================
      # copy-mode-vi 快捷键与行为
      # ============================================================
      # 进入 copy-mode 时光标变为方块, 退出时恢复为竖线
      set-hook -g pane-mode-changed 'if -F "#{m:*copy-mode*,#{pane_mode}}" "set -p cursor-style block" "set -p cursor-style bar"'
      # 进入 copy-mode
      bind M-v copy-mode
      # 选择与复制
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi V send-keys -X select-line
      bind-key -T copy-mode-vi M-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # 光标移动
      bind-key -T copy-mode-vi h send-keys -X cursor-left
      bind-key -T copy-mode-vi j send-keys -X cursor-down
      bind-key -T copy-mode-vi J send-keys -N 5 -X cursor-down
      bind-key -T copy-mode-vi k send-keys -X cursor-up
      bind-key -T copy-mode-vi K send-keys -N 5 -X cursor-up
      bind-key -T copy-mode-vi l send-keys -X cursor-right
      bind-key -T copy-mode-vi w send-keys -X next-word-end
      bind-key -T copy-mode-vi H send-keys -X start-of-line
      bind-key -T copy-mode-vi L send-keys -X end-of-line
      bind-key -T copy-mode-vi n send-keys -X search-again
      bind-key -T copy-mode-vi N send-keys -X search-reverse
    '';
  };
}
