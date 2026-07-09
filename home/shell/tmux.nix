{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # --- --- --- 基本设置 --- --- ---
    # 设置 prefix 键 (Alt + /)
    prefix = "M-/";

    # 鼠标控制
    mouse = true;

    # 开启终端色彩支持
    terminal = "tmux-256color";

    # 配置 vi 模式
    keyMode = "vi";

    # 更改 window 的起始编号为 1
    baseIndex = 1;

    # 快捷键响应速度 (对应原配置注释掉的 escape-time)
    escapeTime = 0;

    # --- --- --- 插件 --- --- ---
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      nord
    ];

    # --- --- --- 无法直接翻译为 nix 配置的 tmux 配置 --- --- ---
    extraConfig = ''
      			# 开启 tmux 直通模式 (即使 pane 不可见也允许透传)
      			set -g allow-passthrough all

      			## 使 tmux 识别 RGB 颜色
      			set -as terminal-features 'tmux-256color:RGB'

      			# 启用焦点事件
      			# set -g focus-events on

      			# 开启高级键盘协议支持
      			set -s extended-keys on

      			# 允许 xterm 风格的键序列
      			set -as terminal-features 'xterm*:extkeys'

      			# 用 prefix + Alt&m 切换状态栏显示/隐藏
      			bind -n M-m if -F "#{==:#{status},on}" "set -g status off" "set -g status on" \; refresh-client -S
      			## 启动 tmux 时默认隐藏状态栏
      			set -g status off

            # 颜色设置
            ## 配置 pane 分割线颜色
            ### 普通分割线：黑色
            set -g pane-border-style "fg=black"
            ### 活动分割线背景色
            set -g pane-active-border-style "fg=white,bg=black"

      			# session 选择快捷键
      			bind -n M-s choose-session
      			# 重命名 session
      			bind -n M-S command-prompt -I "#S" "rename-session '%%'"

      			# 更改 pane 的起始编号为 1 (原生 baseIndex 仅针对 window)
      			set -g pane-base-index 1
      			## 在关闭窗口后自动重新编号
      			set -g renumber-windows on

      			# 基本快捷键设置
      			## 重新加载配置文件
      			bind r source-file ~/.config/tmux/tmux.conf \; display-message "~/.config/tmux/tmux.conf reloaded!"
      			## 快速重命名窗口
      			bind -n M-R command-prompt -I "#W" "rename-window '%%'"
      			## 快速重命名当前 Pane
      			bind -n M-r command-prompt -I "#P" "select-pane -T '%%'"
      			## 显示当前 pane 的标题栏
      			set -g pane-border-status top
      			## 最大化/还原 当前 pane
      			bind -n M-f resize-pane -Z
      			## 配置 detach
      			bind -n M-d detach
      			bind -n M-q detach
      			## 配置关闭当前 pane
      			bind -n M-x kill-pane

      			# 设置切换窗口键
      			## 取消默认的窗口切换方式
      			unbind n
      			unbind p
      			## 新的窗口切换方式
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
      			bind -n M-0 select-window -t 0
      			## 关闭/退出 当前窗口
      			bind -n M-Q kill-window
      			## 新建窗口
      			bind -n M-c new-window
      			## 轮询改变 window 编号
      			bind-key -n M-- swap-window -t -1 \; previous-window
      			bind-key -n M-= swap-window -t +1 \; next-window

      			# 设置切换 pane 快捷键
      			## 分屏
      			bind M-k split-window -vb -c "#{pane_current_path}"
      			bind M-j split-window -v -c "#{pane_current_path}"
      			bind M-h split-window -hb -c "#{pane_current_path}"
      			bind M-l split-window -h -c "#{pane_current_path}"
      			## 改变 pane 焦点
      			bind -n M-h select-pane -L
      			bind -n M-l select-pane -R
      			bind -n M-k select-pane -U
      			bind -n M-j select-pane -D
      			## 挪动 pane 到指定窗口
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
      			## 拖动 pane 交换位置
      			bind -n M-] swap-pane -D
      			bind -n M-[ swap-pane -U
      			bind -n M-| next-layout
      			## 挪动 pane 并自动跳转
      			bind -n M-P join-pane -t :-
      			bind -n M-N join-pane -t :+
      			## 以当前的 pane 新建 window
      			bind -n M-F break-pane
      			## 改变 Pane 尺寸
      			bind -n M-H resize-pane -L 1
      			bind -n M-L resize-pane -R 1
      			bind -n M-K resize-pane -U 1
      			bind -n M-J resize-pane -D 1

      			# 配置 vi 模式下的 copy-mode 快捷键
      			bind-key -T copy-mode-vi V send-keys -X begin-selection
      			bind-key -T copy-mode-vi C-V send-keys -X rectangle-toggle
      			bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
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

      			# 配置 copy-mode
      			## 常驻 emacs 模式
      			set -g status-keys emacs
      			## 进入 copy-mode 快捷键
      			bind -n M-V copy-mode
      		'';
  };
}
