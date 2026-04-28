{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;

    # --- 包与补全 ---

    # 使用 nixpkgs 提供的 fish 包(可替换为 fish 其他版本)
    package = pkgs.fish;

    # 基于已安装 man 页面自动生成补全文件(默认为 true)
    generateCompletions = true;

    # --- Shell 初始化(所有 shell)---
    shellInit = ''
      # 此处代码在每次 fish 启动时执行(登录 / 非登录 / 交互 / 非交互均执行)
    '';

    # --- 登录 Shell 初始化 ---
    loginShellInit = ''
      # 此处代码仅在登录 shell 时执行
      # 例如：设置仅登录时需要的环境变量、启动 tmux / ssh-agent 等
    '';

    # --- 交互式 Shell 初始化(VI 模式、光标、提示符)---
    interactiveShellInit = ''
      # -------- 启用 VI 键绑定 --------
      fish_vi_key_bindings

      # -------- 关闭启动欢迎语 --------
      set -g fish_greeting ""

      # -------- VI 模式提示符 --------
      function fish_mode_prompt
        switch $fish_bind_mode
          case default
            set_color --bold red
            echo "[N]"
          case insert
            set_color --bold green
            echo "[I]"
          case replace_one
            set_color --bold yellow
            echo "[R]"
          case visual
            set_color --bold magenta
            echo "[V]"
        end
        set_color normal
      end

      # -------- VI 模式光标形状(仅支持支持 DECSCUSR 的终端)--------
      # 普通模式     → 方块
      set -g fish_cursor_default block
      # 插入模式     → 竖线
      set -g fish_cursor_insert line
      # 可视模式     → 方块
      set -g fish_cursor_visual block
      # 替换模式     → 下划线
      set -g fish_cursor_replace_one underscore
      set -g fish_cursor_replace underscore
      # 外部命令执行时 → 竖线
      set -g fish_cursor_external line
    '';

    # --- Shell 最后初始化 ---
    shellInitLast = ''
      # 此处代码在 fish 启动流程的最后执行
      # 适用于需要在所有其他配置就绪后才能运行的命令
    '';

    # --- 插件 ---
    plugins = [
      # 长时间运行命令结束后发送桌面通知
      { name = "done"; src = pkgs.fishPlugins.done.src; }
      # fzf 模糊搜索集成(Ctrl+R 历史搜索、Ctrl+T 文件搜索等)
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      # 自动补全配对的括号、引号
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
    ];

    # --- 缩写(abbr)---
    # 输入缩写后按空格 / 回车自动展开为完整命令; 展开后仍可编辑
    # 若其他模块也为 fish 定义了别名, 可启用 preferAbbrs 以优先使用缩写
    preferAbbrs = true;
    shellAbbrs = {
      # # Git
      # g = "git";
      # gs = "git status";
      # ga = "git add";
      # gc = "git commit";
      # gp = "git push";
      # gl = "git pull";
      # gco = "git checkout";
      # gd = "git diff";
      # gb = "git branch";
      # # Nix / Home Manager
      # nrs = "sudo nixos-rebuild switch --flake .";
      # hms = "home-manager switch --flake .";
      # # 常用
      # ".." = "cd ..";
      # "..." = "cd ../..";
    };

    # --- 别名 ---
    # 别名在输入时实时替换, 无法在替换后编辑
    shellAliases = {
      ff = "fastfetch";
      lg = "lazygit";
      rsync = "rsync -arvP";
      px = "proxychains4 -f ~/.config/proxychains/proxychains.conf -q";
    };

    # --- 键绑定 ---
    binds = {
      # 退出到普通模式
      ctrl-q = {
        mode = "insert";
        setsMode = "default";
        command = "true";
        repaint = true;
      };
    };

    # --- 自定义函数 ---
    functions = {
      # # 创建目录并立即进入
      # mcd = "mkdir -p $argv[1] && cd $argv[1]";
      # # 快速备份文件
      # bak = "cp $argv[1] $argv[1].bak";
      # # 显示文件的权限位（八进制）
      # perms = "stat -c '%a %n' $argv";
      # # 创建临时目录并进入
      # tmpd = "cd (mktemp -d)";
      # # 解压各种压缩格式（自动识别）
      # extract = ''
      # set -l file $argv[1]
      # if test -z "$file"
      # echo "用法: extract <文件>"
      # return 1
      # end
      # if test -f "$file"
      # switch $file
      # case '*.tar.bz2'; tar xjf $file
      # case '*.tar.gz';  tar xzf $file
      # case '*.bz2';     bunzip2 $file
      # case '*.rar';     unrar x $file
      # case '*.gz';      gunzip $file
      # case '*.tar';     tar xf $file
      # case '*.tbz2';    tar xjf $file
      # case '*.tgz';     tar xzf $file
      # case '*.zip';     unzip $file
      # case '*.Z';       uncompress $file
      # case '*.7z';      7z x $file
      # case '*';         echo "'$file' 无法识别的压缩格式"
      # end
      # else
      # echo "'$file' 不是有效文件"
      # end
      # '';
    };

    # --- 自定义补全 ---
    # 为不在标准路径中的命令添加补全
    completions = { };
  };

  # ============================================================
  # 环境变量
  # ============================================================
  home.sessionVariables = {
    # 默认编辑器
    EDITOR = "nvim";
    # Rust 详细回溯
    RUST_BACKTRACE = "1";
    # Rust 安装源 (rsproxy 镜像)
    RUSTUP_DIST_SERVER = "https://rsproxy.cn";
    RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
  };

  # ============================================================
  # PATH 扩展
  # ============================================================
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/Projects/bin"
    "$HOME/.cargo/bin"
  ];
}
