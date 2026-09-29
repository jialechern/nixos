{ pkgs, ... }:

{
  # --- --- --- 安装必要的命令行工具 --- --- ---
  home.packages = with pkgs; [
    # zsh 插件包
    zsh-completions
  ];

  # --- --- --- zsh 配置 --- --- ---
  # 注: 通用别名(含 nclean) / PATH 见 ./common.nix
  programs.zsh = {
    enable = true;
    # 注: enableCompletion 与 history.{size,path,ignoreDups,share} 都等于 HM 默认值
    # (true / 10000 / $HOME/.zsh_history / true / true), 不再显式声明
    autosuggestion.enable = true; # 自动补全
    syntaxHighlighting.enable = true; # 语法高亮

    # 注意: 不要用 plugins 引 zsh-completions —— 该包只装 share/zsh/site-functions/
    # (无 *.plugin.zsh), HM 的 `[[ -f ... ]] && source` 会静默跳过。补全实际来自
    # HM 注入的 fpath ($profile/share/zsh/site-functions), 包仍由 home.packages 安装。

    # 需要最后加载的 zsh 配置
    # (通用别名见 ./common.nix)
    initContent = ''
      			# 基础按键绑定(vi 模式)
      			bindkey -v
      			
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
