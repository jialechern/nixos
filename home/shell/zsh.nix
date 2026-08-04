{ config, pkgs, lib, ... }:

{
  # --- --- --- 安装必要的命令行工具 --- --- ---
  home.packages = with pkgs; [
    # zsh 插件包
    zsh-completions
  ];

  # --- --- --- 环境变量与 PATH --- --- ---
  home.sessionVariables = { };


  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  # --- --- --- zsh 配置 --- --- ---
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

    # 别名
    shellAliases = {
      ff = "fastfetch";
      lg = "lazygit";
      rsync = "rsync -arvP";
      px = "proxychains4 -f ${config.xdg.configHome}/proxychains/proxychains.conf -q";
      ngens = "nix profile history --profile /nix/var/nix/profiles/system";
      cliph = "cliphist list | fzf | cliphist decode | wl-copy";
      tm = "tmux new-session -A -s main";
    };

    # 需要最先加载的 zsh 配置
    initExtraFirst = ''
        '';

    # 需要最后加载的 zsh 配置
    initContent = ''
      			# 基础按键绑定(vi 模式)
      			bindkey -v
      			
      			# 使用 Ctrl+q 代替 ESC 进入 normal 模式(需先关闭终端流控)
      			stty -ixon
      			bindkey -M viins '^Q' vi-cmd-mode

      			# vi 模式光标形状: 插入=竖线, 普通/可视=方块
      			zle-keymap-select() {
      			  printf '\e[%d q' $(( $KEYMAP == vicmd ? 2 : 6 ))
      			}
      			zle -N zle-keymap-select

      			# 启动时确保光标为竖线 (默认进入插入模式)
      			zle-line-init() { printf '\e[6 q' }
      			zle -N zle-line-init
      			
      			# PATH 追加
            export PATH=$HOME/.local/bin:$PATH
            [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

            # 一键清理 NixOS 旧系统世代与 Nix Store 垃圾
            nclean() {
              echo "=> 清理 NixOS 旧世代 & 垃圾回收 Nix Store ..."
              sudo nix-collect-garbage -d
              echo "=> 清理完成。"
            }

            # Alt+t: 打开/切回 main tmux session
            tmux-main-session() { tmux new-session -A -s main }
            zle -N tmux-main-session
            bindkey '\et' tmux-main-session
    '';
  };
}
