{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    # 启用 Bash 自动补全(依赖 pkgs.bash-completion)
    enableCompletion = true;

    # --- --- --- 历史记录 --- --- ---
    # 内存中保留的历史命令条数
    historySize = 10000;
    # 历史文件中保留的命令条数
    historyFileSize = 100000;
    # 历史去重：忽略连续重复命令、忽略以空格开头的命令
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    # 不记录到历史的命令(这些命令通常没有回顾价值)
    historyIgnore = [
      "ls"
      "cd"
      "exit"
      "clear"
    ];

    # --- --- --- Shell 选项(shopt) --- --- ---
    shellOptions = [
      "histappend"   # 追加到历史文件而非覆盖
      "extglob"      # 扩展通配符
      "globstar"     # ** 递归匹配所有层级目录
      "checkjobs"    # 退出时警告仍在运行的后台作业
      "cdspell"      # cd 时自动纠正少量拼写错误
      "checkwinsize" # 每次命令后检查终端窗口尺寸
    ];

    # --- --- --- 环境变量 --- --- ---
    sessionVariables = {};

    # --- --- --- 别名设置 --- --- ---
    shellAliases = {
      ff = "fastfetch";
      lg = "lazygit";
      rsync = "rsync -arvP";
      px = "proxychains4 -f ${config.xdg.configHome}/proxychains/proxychains.conf -q";
    };

    # --- --- --- .bashrc 级配置(所有 Bash 调用均执行) --- --- ---
    bashrcExtra = ''
      # 历史命令时间戳格式(用于 history 命令输出和审计)
      HISTTIMEFORMAT="%F %T  "

      # less 传送 ANSI 颜色序列，使 man 手册和日志可读
      export LESS="-R"

      # 一键清理 NixOS 旧系统世代与 Nix Store 垃圾
      nclean() {
        echo "=> 清理 NixOS 旧世代 & 垃圾回收 Nix Store ..."
        sudo nix-collect-garbage -d
        echo "=> 清理完成。"
      }
    '';

    # --- --- --- 交互式 Shell 级配置 --- --- ---
    initExtra = ''
      # vi 编辑模式(命令行操作风格贴近系统管理场景)
      set -o vi

      # 释放 <C-q>/<C-s> 的终端流控功能, 使其可用于 Readline 键绑定
      stty -ixon 2>/dev/null

      # <C-q> 从插入模式进入 Normal(vi-movement) 模式
      bind -m vi-insert '"\C-q": vi-movement-mode'

      # vi 模式光标: 每次显示提示符时设竖线 (bash 默认为插入模式)
      # 局限性: Readline 无 vi-mode-change 钩子, 进入 normal 模式时光标仍为竖线
      # 替代方案: 使用 ble.sh (Bash Line Editor) 可支持模式感知光标
      PROMPT_COMMAND='printf "\\e[6 q"'
    '';
  };

  # --- --- --- PATH 路径管理 --- --- ---
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/Projects/bin"
    "$HOME/.cargo/bin"
  ];
}
