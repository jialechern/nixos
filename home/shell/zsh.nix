{ config, pkgs, lib, ... }:

{
  # --- --- --- 安装必要的命令行工具 --- --- ---
  home.packages = with pkgs; [
    # zsh 插件包
    zsh-completions
  ];

  # --- --- --- 环境变量与 PATH --- --- ---
  home.sessionVariables = {
    # --- 编辑器 ---
    EDITOR = "nvim";
    # --- ollama 配置 ---
    OLLAMA_MODELS = "$HOME/LLMS";
    # 启用 GPU
    OLLAMA_FORCE_GPU = "1";
    # --- Rust 配置 ---
    # 打印详细 BACKTRACE
    RUST_BACKTRACE = "1";
    # Rust 代理设置
    RUSTUP_DIST_SERVER = "https://rsproxy.cn";
    RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
  };


  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/Projects/bin"
    "$HOME/.cargo/bin"
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
      px = "proxychains4 -f ~/.config/proxychains/proxychains.conf -q";
    };

    # 需要最先加载的 zsh 配置
    initExtraFirst = ''
        '';

    # 需要最后加载的 zsh 配置
    initContent = ''
      			# 基础按键绑定(vi 模式)
      			bindkey -v
      			
      			# PATH 追加
      			export PATH=$HOME/.local/bin:$HOME/Projects/bin:$PATH
      			[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
      		'';
  };

}
