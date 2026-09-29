{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    # 注: enableCompletion / historySize / historyFileSize 都等于 HM 默认值
    # (true / 10000 / 100000), 不再显式声明; 需要偏离时再加回来

    # --- --- --- 历史记录 --- --- ---
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
    # 注: HM 的 listOf 选项在显式定义时会整体替换默认值 (这里的 default 只在
    # 完全不写本选项时生效), 所以必须把 6 项列全
    shellOptions = [
      "histappend"   # 追加到历史文件而非覆盖
      "extglob"      # 扩展通配符
      "globstar"     # ** 递归匹配所有层级目录
      "checkjobs"    # 退出时警告仍在运行的后台作业
      "cdspell"      # cd 时自动纠正少量拼写错误
      "checkwinsize" # 每次命令后检查终端窗口尺寸
    ];

    # --- --- --- .bashrc 级配置(所有 Bash 调用均执行) --- --- ---
    # 注: 通用别名(含 nclean) / PATH 见 ./common.nix
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

      # vi 模式光标: readline 8.0+ (bash 5.0+ 自带) 的 vi-ins/cmd-mode-string,
      # 模式切换时实时发送 DECSCUSR, 解决原方案"进入 normal 光标不变"的局限
      bind 'set show-mode-in-prompt on'
      bind 'set vi-ins-mode-string \1\e[5 q\2' # 插入模式: 闪烁竖线
      bind 'set vi-cmd-mode-string \1\e[1 q\2' # 普通模式: 闪烁方块
    '';
  };
}
