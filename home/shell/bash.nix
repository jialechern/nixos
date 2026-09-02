{ pkgs, ... }:

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

    # --- --- --- .bashrc 级配置(所有 Bash 调用均执行) --- --- ---
    # 注: 通用别名 / nclean 函数 / PATH 见 ./common.nix
    bashrcExtra = ''
      # 历史命令时间戳格式(用于 history 命令输出和审计)
      HISTTIMEFORMAT="%F %T  "

      # less 传送 ANSI 颜色序列，使 man 手册和日志可读
      export LESS="-R"
    '';

    # --- --- --- 交互式 Shell 级配置 --- --- ---
    initExtra = ''
      # vi 编辑模式(命令行操作风格贴近系统管理场景)
      set -o vi

      # 释放 <C-q>/<C-s> 的终端流控功能, 使其可用于 Readline 键绑定
      stty -ixon 2>/dev/null

      # <C-q> 从插入模式进入 Normal(vi-movement) 模式
      bind -m vi-insert '"\C-q": vi-movement-mode'

      # vi 模式光标: readline 8.0+ (bash 5.0+ 自带) 的 vi-ins/cmd-mode-string,
      # 模式切换时实时发送 DECSCUSR, 解决原方案"进入 normal 光标不变"的局限
      bind 'set show-mode-in-prompt on'
      bind 'set vi-ins-mode-string \1\e[5 q\2' # 插入模式: 闪烁竖线
      bind 'set vi-cmd-mode-string \1\e[1 q\2' # 普通模式: 闪烁方块
    '';
  };
}
