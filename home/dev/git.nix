{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "jialechern";
        email = "jialechern@gmail.com";
      };

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        cm = "commit";
        ps = "push";
        pl = "pull";
        wt = "worktree";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };

      init.defaultBranch = "main";
      core.editor = "nvim";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.quotepath = false;

      # git-lfs 传输调优 (可选, 默认值适合多数场景; 完整选项见 git-lfs-config(5))
      lfs = {
        # 并发上传/下载数, 默认 8
        # concurrenttransfers = 8;
        # 单个对象传输失败的最大重试次数, 默认 8
        # transfer.maxretries = 8;
        # 网络活动超时(秒), 默认 30
        # activitytimeout = 30;
        # 只拉取这些路径的 LFS 对象 (逗号分隔, gitignore 通配)
        # fetchexclude = "*.mp4";
      };
    };

    # ---- Git LFS (大文件存储) ----
    # home-manager 的 lfs 子模块: 安装 git-lfs 包, 并写入 [filter "lfs"] 过滤规则
    # (clean/smudge/process), 使大文件 add 时转成指针、checkout 时自动下载对象。
    lfs = {
      enable = true;
      # package = pkgs.git-lfs; # 默认即 nixpkgs 的 git-lfs, 一般无需覆盖
      skipSmudge = false; # false: 克隆/拉取时自动下载 LFS 对象; true: 跳过, 需手动 git lfs pull
    };

    # 说明: home-manager 的 lfs.enable 只配置过滤规则、不安装 pre-push 钩子,
    # 需要在 LFS 仓库里手动运行 `git lfs install` 来装钩子 (否则 push 不会上传
    # LFS 对象, 只推送指针文件); 大文件跟踪由仓库内 `git lfs track` 管理。

    # 默认忽略的文件
    ignores = [ ".DS_Store" "*.swp" "node_modules" ];
  };

  # 使用 delta diff
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
      theme = "OneHalfDark";
    };
  };
}
