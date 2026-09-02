{ pkgs, ... }:

{
  # --- --- --- 安装必要的命令行工具 --- --- ---
  home.packages = with pkgs; [
    # zsh 插件包
    zsh-completions
  ];

  # --- --- --- zsh 配置 --- --- ---
  # 注: 通用别名 / nclean 函数 / PATH 见 ./common.nix
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # 自动补全
    autosuggestion.enable = true;
    # 语法高亮
    syntaxHighlighting.enable = true;

    # 历史记录
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };

    # 插件
    plugins = [
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
      }
    ];

    # 需要最后加载的 zsh 配置
    # (通用别名见 ./common.nix)
    initContent = ''
      			# 基础按键绑定(vi 模式)
      			bindkey -v
      			
      			# 使用 Ctrl+q 代替 ESC 进入 normal 模式(需先关闭终端流控)
      			stty -ixon
      			bindkey -M viins '^Q' vi-cmd-mode

      			# vi 模式光标形状 (DECSCUSR, 与 fish 一致: 全部闪烁)
      			# 插入=闪烁竖线(5), 普通/可视=闪烁方块(1)
      			zle-keymap-select() {
      			  case $KEYMAP in
      			    vicmd)             printf '\e[1 q' ;;
      			    main|viins)        printf '\e[5 q' ;;
      			  esac
      			}
      			zle -N zle-keymap-select

      			# 启动时确保光标为闪烁竖线 (默认进入插入模式)
      			zle-line-init() { printf '\e[5 q' }
      			zle -N zle-line-init
    '';
  };
}
