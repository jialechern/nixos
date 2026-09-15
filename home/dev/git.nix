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
        sw = "switch";
        df = "diff";
        ds = "diff --staged";
        rb = "rebase";
        ri = "rebase -i"; # 交互式 rebase: git ri HEAD~3
        amend = "commit --amend"; # 追加到上一个提交
        unstage = "restore --staged"; # 取消暂存: git unstage <file>
        root = "rev-parse --show-toplevel"; # 打印仓库根目录
        last = "log -1 HEAD --stat"; # 查看最近一次提交及其改动文件
      };

      # ---- 基础 ----
      init.defaultBranch = "main";
      core.editor = "nvim";
      core.quotepath = false; # 非 ASCII 路径直接显示, 不做八进制转义

      # ---- 拉取 / 变基 ----
      pull.rebase = true;
      rebase.autoStash = true; # 脏工作区也能 rebase / pull --rebase (结束自动恢复)
      rebase.updateRefs = true; # 级联移动栈式分支上的其他分支 (需 git >= 2.38)
      rebase.autoSquash = true; # fixup!/squash! 提交自动归位
      rebase.abbreviateCommands = true; # todo 列表用 p/r/s/f 简写
      rebase.missingCommitsCheck = "warn"; # 交互式 rebase 误删 todo 行时提醒 (默认 ignore 会静默丢弃)
      rerere.enabled = true; # 记住冲突解法, 同一冲突下次自动解决
      rerere.autoupdate = true; # 自动解决后直接标记为已暂存
      merge.conflictStyle = "zdiff3"; # 冲突块附带原始内容, 比默认 merge 更好读
      fetch.prune = true; # 远端已删除的分支本地自动清理
      fetch.writeCommitGraph = true; # 每次 fetch 增量写 commit-graph, 加速 log / blame
      checkout.defaultRemote = "origin"; # 有多个 remote 时, git checkout <分支> 仍能隐式跟踪 origin

      # ---- 推送 ----
      push.autoSetupRemote = true; # 新分支 push 自动建立上游跟踪
      push.useForceIfIncludes = true; # force push 须显式指定, 避免覆盖他人提交
      push.followTags = true; # 推送时带上可达的附注标签

      # ---- 提交 ----
      commit.verbose = true; # 提交时在编辑器里附带 diff

      # ---- 性能 (大仓库 / 大工作区) ----
      index.version = 4; # 索引路径压缩 (2.55 新仓库默认仍是 2), jj 已实测兼容
      core.untrackedCache = true; # 缓存未跟踪文件扫描结果

      # ---- 显示与检索 ----
      diff.algorithm = "histogram"; # 默认 myers; histogram 的 diff 更贴近直觉
      grep.patternType = "perl"; # grep 默认用 PCRE (\d \w 等可用)
      log.date = "iso"; # 日志时间用 ISO 8601 (默认相对时间)
      branch.sort = "-committerdate"; # 分支列表按最近提交排序
      tag.sort = "version:refname"; # 标签按版本号排序 (v1.9 < v1.10)
      column.ui = "auto"; # 输出到终端时用列布局 (默认 never)

      # ---- 安全 ----
      transfer.credentialsInUrl = "warn"; # URL 中携带明文凭据时告警 (默认 allow)

      # git-lfs 传输调优 (可选, 默认值适合多数场景; 完整选项见 git-lfs-config(5))
      lfs = {
        # 并发上传/下载数, 默认 8
        concurrenttransfers = 8;
        # 网络活动超时(秒), 默认 30
        # activitytimeout = 30;
        # 只拉取这些路径的 LFS 对象 (逗号分隔, gitignore 通配)
        # fetchexclude = "*.mp4";
      };
      # 注意: 键名带点的多层配置必须写成顶层字符串键 (如下行的 "lfs.transfer"),
      #   写成 lfs = { "transfer.maxretries" = 8; } 会生成非法的
      #   [lfs] transfer.maxretries = 8 —— git 会直接报 "错误的配置行" 无法解析;
      #   下面这行生成 [lfs "transfer"] maxretries = 8, 与 lfs.transfer.maxretries 等价。
      # "lfs.transfer".maxretries = 8; # 单个对象传输失败的最大重试次数, 默认 8
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

    # 全局忽略清单 (写入 ~/.config/git/ignore, git 默认即读取该 XDG 路径)
    ignores = [
      # macOS / 编辑器临时文件
      ".DS_Store"
      "*~" # 编辑器备份文件
      "*.swp"
      "*.swo"
      # Python
      "__pycache__/"
      "*.py[cod]"
      # JS / TS
      "node_modules"
      # Nix 构建产物与 direnv
      "result"
      "result-*"
      ".direnv/"
    ];
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
