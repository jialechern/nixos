{ config, ... }:

# ============================================================================
# Jujutsu (jj) —— 与 Git 兼容的新一代分布式版本控制系统
#
# 配置依据:
#   * home-manager 模块 programs.jujutsu (settings 原样写入 ~/.config/jj/config.toml)
#   * 官方手册   https://docs.jj-vcs.dev/latest/config.html
#     (离线查看: `jj help -k config`; 语法手册: `jj help -k revsets/templates/filesets`)
#   * 内置默认值 `jj config list --include-defaults`
#   * 排查命令: `jj config list` / `jj config get <键>` / `jj config path --user`
#
# 阅读约定:
#   * 未注释 = 已生效; 注释掉的 = 备选配置, 需要时取消注释即可
#   * 注释中的 "(默认 ...)" 指 jj 内置默认值, 便于与官方文档对照
#   * 本文件只管理用户级配置; 仓库级/工作区级配置存放在仓库 .jj/ 下, 优先级更高
#
# 配置优先级 (后者覆盖前者):
#   内置默认 < /etc/jj/config.toml < ~/.jjconfig.toml
#   < ~/.config/jj/config.toml < ~/.config/jj/conf.d/*.toml
#   < 仓库级 < 工作区级 < 命令行 --config / --config-file
#
# 注意: config.toml 由 home-manager 生成 (指向 nix store 的只读符号链接),
#   请勿用 `jj config set --user` 直接修改 (会顶替符号链接, 下次 rebuild 被备份为
#   ~/.config/jj/config.toml.backup); 长期修改请改本文件, 临时覆盖用:
#     jj --config ui.color=never log
#   手写的 ~/.config/jj/conf.d/*.toml 不受 HM 管理且优先级更高, 适合机器/项目特例。
# ============================================================================

let
  # 复用 git.nix 中的身份信息 (user.name / user.email), 避免两处维护
  gitUser = config.programs.git.settings.user;
in
{
  programs.jujutsu = {
    enable = true;

    # package = pkgs.jujutsu;   # 默认即 nixpkgs 的 jujutsu (当前 0.45.1)
    #                           # 包内自带 bash/fish/zsh/nushell 补全与 man 手册, 无需额外配置

    # ediff = false;            # 默认跟随 programs.emacs.enable; 此处未启用 emacs 故为 false

    settings = {
      # ======================================================================
      # 1. 用户身份 (user)
      # ======================================================================
      # 未设置时 jj 会使用空身份并提示; 这里直接复用 git 配置
      user = {
        name = gitUser.name;
        email = gitUser.email;
      };

      # ======================================================================
      # 2. 操作元数据 (operation)
      # ======================================================================
      # jj op log 中记录的操作用户与主机名; 默认取系统用户名与 hostname,
      # 多机共用同一仓库 (同步 .jj) 时可显式区分来源
      # operation = {
      #   username = "jialechern";
      #   hostname = "omen";
      # };

      # ======================================================================
      # 3. 界面 (ui)
      # ======================================================================
      ui = {
        # 着色: always / never / debug / auto (默认 auto, 仅在输出到终端时着色)
        color = "auto";

        # 不带子命令时执行的命令 (默认 ["log"]), 可带参数:
        # default-command = ["log" "--reversed"];
        default-command = ["log"];

        # 编辑器; 优先级: $JJ_EDITOR > ui.editor > $VISUAL > $EDITOR
        editor = "nvim";

        # 分页: auto (默认) / never (等价 --no-pager)
        # 分页器本身由 delta 接管 (见文件末尾 programs.delta.enableJujutsuIntegration),
        # 即 ui.pager = <delta>, ui.diff-formatter = ":git", 以便 delta 渲染 diff。
        # 若想改用 jj 默认分页器 (less -FRXK):
        # pager = { command = ["less" "-FRXK"]; env.LESSCHARSET = "utf-8"; };
        # 也可用字符串 ["sh" "-c" "diff-so-fancy | less -RFX"] 串联格式化工具;
        # 环境变量 $JJ_PAGER 可临时覆盖 ($PAGER 不被 jj 使用)
        paginate = "auto";

        # 提交图样式: curved (默认) / square / ascii / ascii-large
        graph.style = "curved";

        # 日志内容超出终端宽度时自动换行 (默认 false)
        log-word-wrap = false;

        # 其余 UI 开关 (列出内置默认值, 按需修改):
        # diff-instructions = true;          # 编辑 diff 时生成 JJ-INSTRUCTIONS 说明文件
        # progress-indicator = true;         # 显示进度条
        # quiet = false;                     # 减少非必要输出
        # log-synthetic-elided-nodes = true; # 被省略的图段显示为合成节点 "~"
        # show-cryptographic-signatures = false; # 在 log 中显示/校验提交签名 (有性能开销)
        # movement.edit = false;             # prev/next 默认等价带 --edit (适合 edit-based 工作流)

        # 冲突标记风格: diff (jj 默认, jj 智能格式) / snapshot / git (Git diff3)
        # 已启用 git 风格: nvim 与多数外部工具都能识别 diff3 标记 (jj 默认的 diff 风格仅 jj 本身可解析)
        conflict-marker-style = "git";

        # 书签/标签列表排序; 可用键: name / author-name / author-email / author-date /
        # committer-name / committer-email / committer-date, 键后加 "-" 表示降序
        # bookmark-list-sort-keys = ["committer-date-"];
        # tag-list-sort-keys = ["name"];

        # 内置分页器 ":builtin" (streampager) 专有配置:
        # pager = ":builtin";
        # streampager = {
        #   interface = "quit-if-one-page";  # 默认; 还有 full-screen-clear-output / quit-quickly-or-clear-output
        #   wrapping = "anywhere";           # 默认; word 按词换行 / none 横向滚动 (类似 less -S)
        #   show-ruler = true;               # 默认显示标尺
        # };

        # ---- diff 编辑器 (jj split -i / jj squash -i / jj diffedit) ----
        # :builtin 为内置终端 TUI (默认);
        # diff-editor = "meld";        # 使用 merge-tools.meld.edit-args
        # diff-editor = "meld-3";      # 三栏视图 (左/右 diff + 中间编辑), 需安装 meld
        # diff-editor = "diffedit3";   # 三栏视图, 浏览器 UI, 适合 SSH
        # diff-editor = ["/path/to/tool" "$left" "$right"];
        # merge-tools.<tool>.edit-args = ["$left" "$right" "$output"];          # $output 出现即为三栏
        # merge-tools.<tool>.edit-invocation-mode = "file-by-file";             # 逐文件调用 (默认 dir)
        # ui.diff-instructions = false;  # 不生成 JJ-INSTRUCTIONS

        # ---- 三方合并 (jj resolve) ----
        # 内置可用: kdiff3 / meld (2 栏) / mergiraf (结构化自动合并) / smerge /
        #          vimdiff / vscode / vscodium; 需在 PATH 中
        # merge-editor = "vimdiff";
        # merge-editor = ["meld" "$left" "$base" "$right" "-o" "$output"];
        # 自定义工具可替换的变量: $left $right $base $output $marker_length $path
        # merge-tools.<tool>.merge-args = ["$base" "$left" "$right" "-o" "$output"];
        # merge-tools.<tool>.merge-conflict-exit-codes = [1];              # 退出码 1 也视为"含冲突标记的正常输出"
        # merge-tools.<tool>.merge-tool-edits-conflict-markers = true;     # 允许工具直接编辑冲突标记
        # merge-tools.<tool>.conflict-marker-style = "git";                # 该工具专用的冲突标记风格
      };

      # ======================================================================
      # 4. 颜色 (colors)
      # ======================================================================
      # 键是 jj 的 label 名 (完整列表见 jj 源码 cli/src/config/colors.toml,
      # 也可用 `jj --color=debug log` 查看当前输出用到的 label)。
      # 常用 label: commit_id / change_id / author / committer / timestamp /
      #   bookmark / bookmarks / local_bookmarks / remote_bookmarks / tag / git_ref /
      #   conflict / divergent / empty / elided / root / working_copy /
      #   "working_copy commit_id" / "diff header" / "diff added" / "diff removed" /
      #   "diff added token" / "diff removed token" / "diff context line_number" /
      #   "diff file_header" / "diff hunk_header" / "node immutable" / "node conflicted" /
      #   "operation id" / "operation user" ...
      # 样式字段: fg / bg / bold / dim / italic / underline / crossed-out / reverse;
      # 颜色值: black..white (含 "bright xxx") / "default" / "#rrggbb" / "ansi-color-<0-255>"
      # colors = {
      #   commit_id = "green";
      #   change_id = "#ff1525";
      #   "working_copy commit_id" = { underline = true; };     # 未覆盖的样式继承父 label
      #   "diff added token" = { bg = "#002200"; underline = false; };
      #   "diff context" = { dim = true; };
      # };

      # ======================================================================
      # 5. diff 格式细节 (diff) —— delta 负责渲染, 这里控制 jj 生成的 diff 内容
      # ======================================================================
      # diff = {
      #   git.context = 3;                        # git 风格 diff 的上下文行数 (默认 3)
      #   git.show-path-prefix = true;            # 显示 a/ b/ 路径前缀 (默认 true)
      #   color-words.context = 3;                # (默认 3)
      #   color-words.max-inline-alternation = 3; # 行内改写内联显示的最大交替次数 (默认 3, -1 全部内联, 0 关闭)
      #   color-words.conflict = "materialize";   # materialize (默认) / pair (逐对比较)
      #   stat.max-bar-width = 10;                # --stat 的 ++-- 条最大宽度 (默认不限, 占满剩余空间)
      # };

      # ======================================================================
      # 6. 命令别名 (aliases)
      # ======================================================================
      # jj 自带别名: b = bookmark, ci = commit, desc = describe, st = status
      # 定义 = [命令, 参数...]; 写成 { definition, doc } 时 doc 会显示在 shell 补全中
      aliases = {
        co = {
          definition = [ "edit" ];
          doc = "检出/编辑某提交 (≈ git checkout)";
        };
        cm = {
          definition = [ "commit" ];
          doc = "提交当前工作副本 (≈ git commit)";
        };
        br = {
          definition = [ "bookmark" ];
          doc = "书签(≈分支)管理 (≈ git branch)";
        };
        ps = {
          definition = [ "git" "push" ];
          doc = "推送 (≈ git push)";
        };
        pl = {
          definition = [ "git" "fetch" ];
          doc = "拉取 (≈ git pull; jj 会自动 rebase 本地后代)";
        };
        wa = {
          definition = [ "workspace" "add" ];
          doc = "新建工作区 (≈ git worktree add)";
        };
        wl = {
          definition = [ "workspace" "list" ];
          doc = "列出工作区 (≈ git worktree list)";
        };
        lg = {
          definition = [ "log" "-r" "::@" ];
          doc = "显示 @ 全部祖先的日志";
        };
        l = {
          definition = [ "log" "-r" "(trunk()..@):: | (trunk()..@)-" ];
          doc = "显示未合入 trunk 的提交及其后代";
        };
        # 需要多命令/脚本时可用 util exec (能做任意事, 注意安全, 详见手册 Aliases 一节):
        # sync = {
        #   definition = [ "util" "exec" "--" "bash" "-c" "set -euo pipefail; jj git fetch; jj rebase -b @ -d 'trunk()'" "" ];
        #   doc = "fetch 并把当前分支 rebase 到 trunk";
        # };
      };

      # ======================================================================
      # 7. revset (revsets / revset-aliases)
      # ======================================================================
      # revsets: 各命令默认使用的 revision 集合 (无 -r 参数时)
      # revsets = {
      #   log = "builtin_log()";               # (默认) = present(@) | ancestors(immutable_heads().., 2) | trunk()
      #   # log = "main@origin..";             # 例: 只显示未推送到 origin/main 的提交
      #   short-prefixes = "mutable()";        # ID 短前缀的作用范围 (默认取 revsets.log; 缩小可避免前缀变长)
      #   log-graph-prioritize = "present(@)"; # log 图中优先靠左对齐的集合 (默认 present(@))
      #   op-diff-changes-in = "mutable() | immutable_heads()";  # op diff 中视为"重要"的集合
      #   # 其余默认集合: converge = "mutable() & divergent()",
      #   #   fix/run/sign/simplify-parents/arrange = "reachable(@, mutable())"
      #   # bookmark-advance-from = "heads(::to & bookmarks())", bookmark-advance-to = "@"
      # };

      # revset-aliases: 自定义 revset 符号/函数 (可在命令行 -r 中直接使用)
      # "revset-aliases" = {
      #   # 追加不可变集合 (默认 builtin_immutable_heads() = trunk() | tags() | untracked_remote_bookmarks())
      #   "immutable_heads()" = "builtin_immutable_heads() | release@origin";
      #   # 防止改写他人提交: "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
      #   wip = "heads(::@ ~ description(''))::";   # 用法: jj log -r wip
      #   'closest_pushable(to)' = 'heads(::to & mutable() & ~description(exact:"") & (~empty() | merges()))';
      # };

      # ======================================================================
      # 8. 模板 (templates / template-aliases)
      # ======================================================================
      # templates: 各命令的输出模板; 内置模板别名可直接引用, 例如
      #   builtin_log_compact(默认) / builtin_log_comfortable / builtin_log_detailed /
      #   builtin_log_oneline / builtin_log_compact_full_description / builtin_log_node(_ascii) /
      #   builtin_evolog_compact / builtin_op_log_compact / builtin_op_log_comfortable /
      #   builtin_op_log_oneline / builtin_op_log_node(_ascii) / builtin_config_list(_detailed) /
      #   builtin_workspace_list / builtin_draft_commit_description(_with_diff)
      templates = {
        # 已启用: jj config list 会附带每个值的来源文件与"是否被覆盖"标记, 便于排查配置
        config_list = "builtin_config_list_detailed";

        # 其余模板均为内置默认值, 需要时取消注释 (可用别名见上方列表):
        # log = "builtin_log_compact";
        # show = "builtin_log_detailed";
        # evolog = "builtin_evolog_compact";
        # op_log = "builtin_op_log_compact";
        # op_show = "builtin_op_log_compact";
        # arrange = "builtin_log_compact";      # jj arrange TUI 的模板
        # bookmark_list = 'format_commit_ref(self, "bookmark") ++ "\n"';
        # tag_list = 'format_commit_ref(self, "tag") ++ "\n"';
        # git_push_bookmark = '"push-" ++ change_id.short()';   # jj git push --change 生成的书签名
        # draft_commit_description = "builtin_draft_commit_description";  # 写提交信息时编辑器内的草稿
        # # draft_commit_description = "builtin_draft_commit_description_with_diff"; # 附带完整 diff
        # new_description = "";                 # jj new 未给 -m 时的默认描述 (可用模板自动生成)
        # duplicate_description = "description";# jj duplicate 的提交信息 (默认复制原描述)
        # # 自动追加 trailer (如 Signed-off-by / Change-Id):
        # # commit_trailers = 'format_signed_off_by_trailer(self) ++ if(!trailers.contains_key("Change-Id"), format_gerrit_change_id_trailer(self))';
        # log_node = "builtin_log_node";        # 图中节点符号 (默认随 graph.style 自动切换)
        # op_log_node = "builtin_op_log_node";
      };

      # template-aliases: 自定义模板片段, 覆盖内置渲染的"外观"
      # "template-aliases" = {
      #   "format_short_id(id)" = "id.shortest(12)";              # 默认 id.shortest(8): 最短唯一前缀, 至少 8 位
      #   "format_short_change_id(id)" = "format_short_id(id).upper()";
      #   "format_timestamp(timestamp)" = 'timestamp.local().format("%Y-%m-%d %H:%M:%S")';  # 默认格式
      #   # "format_timestamp(timestamp)" = "timestamp.ago()";    # 相对时间 "x minutes ago"
      #   "format_short_signature(signature)" = "signature.email()";  # 默认只显示邮箱
      #   # "format_short_signature(signature)" = "signature";    # 姓名 <邮箱>
      #   "commit_timestamp(commit)" = "commit.author().timestamp()"; # 默认显示 committer 时间
      #   "format_time_range(time_range)" = 'time_range.start() ++ " - " ++ time_range.end()'; # op log 用绝对时间
      # };

      # ======================================================================
      # 9. 提交签名 (signing / git.sign-on-push)
      # ======================================================================
      # behavior: drop 从不签名 / keep 保留已有签名 (默认) / own 自己的提交自动签 / force 全部签
      # backend:  none (默认, 关闭) / gpg / gpgsm (PKCS#12) / ssh
      # 手动签: jj sign <rev> / jj unsign <rev>; 显示校验结果: ui.show-cryptographic-signatures = true
      # signing = {
      #   behavior = "own";
      #   backend = "gpg";
      #   # key = "4ED556E9729E000F";                    # gpg -u 接受的任意 key 标识; 默认取 user.email 对应 key
      #   # backends.gpg.program = "gpg2";
      #   # backends.gpg.allow-expired-keys = false;     # (默认)
      # };
      # signing = {
      #   behavior = "own";
      #   backend = "ssh";
      #   key = "~/.ssh/id_ed25519.pub";               # 也可直接写公钥字符串
      #   # backends.ssh.program = "ssh-keygen";        # (默认)
      #   # backends.ssh.allowed-signers = "~/.ssh/allowed_signers";  # 校验他人签名所需的信任列表
      #   # backends.ssh.revocation-list = "~/.ssh/revoked_keys";     # 吊销列表
      # };
      # 懒签名 (仅推送时批量签名, 适合签名慢/需交互的硬件 key):
      # signing.behavior = "drop";
      # git.sign-on-push = true;   # (默认 false)

      # ======================================================================
      # 10. Git 互操作 (git / remotes)
      # ======================================================================
      git = {
        # 新建的 git 仓库 (.jj + .git 共存) 默认即为 colocated 模式; 显式写出以表明选择。
        # 优点: git 命令可直接操作同一仓库; 缺点: 大仓库下部分操作更慢, 且两边同时写入需谨慎
        #
        # 注意: jj 不支持 git-lfs 过滤器 (官方 git-compatibility 文档: "Git LFS: No", issue #80)。
        # jj 会把 LFS 指针文件当普通文本快照, 不会自动转成大文件对象; 需要上传/下载
        # LFS 对象时请在 colocated 工作区里使用 git lfs 命令 (这也是保留 colocate 的理由之一)。
        colocate = true;

        # 其余 git 选项 (默认值):
        # object-hash = "sha1";                  # 新建仓库的对象哈希: sha1 (默认) / sha256 (仅初始化时生效)
        # track-default-bookmark-on-clone = true;# clone 时自动创建跟踪默认远程书签 (如 main)
        # abandon-unreachable-commits = true;    # git 侧不可达的提交在 jj 中标记为废弃
        # record-synthetic-predecessors = true;  # 为 fetch/import 的提交重建 evolution 历史(大仓库可关掉提速)
        # write-change-id-header = true;         # 把 change id 写进 git commit header (供其他 jj 用户识别)
        # private-commits = "none()";            # 禁止推送的 revset, 例: "description('wip:*')";
        # fetch = "origin";                      # jj git fetch 默认远程 (多个远程时默认 origin)
        # push  = "origin";                      # jj git push  默认远程
        # executable-path = "git";               # 调用哪个 git 二进制
        # sign-on-push = false;                  # 推送前自动给未签名的可变提交补签名
      };

      # 单个远程的抓取/跟踪策略 (仓库级常用, 也可写在用户级做默认):
      remotes.origin = {
        # 已启用: 名称匹配的书签自动建立"跟踪"关系。实测 jj 默认不会自动跟踪 fetch 下来的
        # 新远程书签 (fetch 后无法直接推送、看不到 ahead/behind), 开启后行为接近 git。
        # 0.39+ 字符串模式默认按 glob 解析。
        auto-track-bookmarks = "*";

        # 其余可选 (默认不限制):
        # fetch-bookmarks = "~gh-pages";     # 只 fetch 哪些书签 (~ 取反)
        # fetch-tags = "v*";                 # 只 fetch 哪些标签
        # auto-track-created-bookmarks = "*";# 只自动跟踪自己创建的书签 (多人共享仓库时更稳)
      };

      # ======================================================================
      # 11. 三方合并策略 (merge)
      # ======================================================================
      # merge = {
      #   hunk-level = "line";     # 冲突按行 (默认) / word 按词
      #   same-change = "accept";  # 各方做出相同修改时自动采纳 (默认) / keep 保留为冲突
      # };

      # ======================================================================
      # 12. 快照与工作副本 (snapshot / working-copy / fsmonitor)
      # ======================================================================
      snapshot = {
        # 工作副本过期时自动执行 update-stale (默认 false), 多工作区/多机场景省心
        auto-update-stale = true;

        # 自动跟踪新文件 (默认 "all()", 即除 ignore 外全部跟踪); 例: 只跟踪源码
        # auto-track = "glob:'**/*.rs' | glob:'**/*.toml'";
        # 新文件大小上限, 超过则拒绝快照 (默认 "1MiB", 可写 "10MiB" 或字节数, 0 = 不限制)
        # max-new-file-size = "10MiB";
      };

      # working-copy = {
      #   eol-conversion = "none";     # CRLF 转换: none (默认) / input (签入转 LF) / input-output (签入签出都转, ≈ core.autocrlf)
      #   exec-bit-change = "auto";    # 可执行位: auto (默认, 自动探测文件系统) / respect / ignore (跨 Windows 场景)
      # };

      # fsmonitor = {
      #   backend = "none";                          # 大仓库可设 "watchman" 加速快照 (需安装 watchman)
      #   watchman.register-snapshot-trigger = false;# 文件变化后自动后台快照
      # };

      # ======================================================================
      # 13. 自动格式化 jj fix / 批量运行 jj run
      # ======================================================================
      # fix.tools.<name>: 命令从 stdin 读文件、stdout 写回; 变量 $root 仓库根, $path 相对路径,
      #   $first/$last 修改行的起止行号 (配合 line-range-args 只格式化改动的行)
      fix.tools = {
        # ---------- Python (ruff, 本机已装) ----------
        ruff = {
          command = [ "ruff" "format" "--stdin-filename" "$path" "-" ];
          patterns = [ "glob:'**/*.py'" ];
        };

        # ---------- Rust (rustfmt, 本机已装) ----------
        # 注: 从 stdin 读取时 rustfmt 默认按 2015 edition 解析, 可在项目的 rustfmt.toml 里写
        #     edition = "2024", 或在本行 command 中追加 "--edition" "2024"
        rustfmt = {
          command = [ "rustfmt" "--emit" "stdout" ];
          patterns = [ "glob:'**/*.rs'" ];
        };

        # ---------- C / C++ / CUDA / ObjC++ (clang-format, 本机已装) ----------
        # 默认读取项目里的 .clang-format, 没有则用 LLVM 风格; --assume-filename 决定语言与配置查找位置
        # 故意不含 '**/*.m': 该扩展名与 MATLAB 冲突, 误格式化会破坏脚本; 需要 Objective-C 时自行加回
        clang-format = {
          command = [ "clang-format" "--assume-filename=$path" ];
          patterns = [
            "glob:'**/*.c'"
            "glob:'**/*.h'"
            "glob:'**/*.cc'"
            "glob:'**/*.hpp'"
            "glob:'**/*.cpp'"
            "glob:'**/*.hh'"
            "glob:'**/*.cxx'"
            "glob:'**/*.hxx'"
            "glob:'**/*.cu'"
            "glob:'**/*.mm'"
          ];
          # 老代码/大文件不想整体重排时可只格式化改动行:
          # line-range-args = [ "--lines=$first:$last" ];
        };

        # ---------- Haskell (ormolu, 本机已装) ----------
        # --stdin-input-file 用于按文件位置定位项目的 .cabal / .ormolu 配置
        # 备选: pkgs.fourmolu (同接口, 可配置项更多) / pkgs.stylish-haskell
        ormolu = {
          command = [ "ormolu" "--stdin-input-file" "$path" ];
          patterns = [ "glob:'**/*.hs'" "glob:'**/*.hs-boot'" ];
        };

        # ---------- JavaScript / TypeScript / 前端 (prettier) ----------
        # 会读取项目的 .prettierrc / prettier.config.js; 默认按扩展名自动选 parser
        # 备选: pkgs.biome (更快) 或已装的 deno (deno fmt -)
        prettier = {
          command = [ "prettier" "--stdin-filepath" "$path" ];
          patterns = [
            "glob:'**/*.js'"
            "glob:'**/*.mjs'"
            "glob:'**/*.cjs'"
            "glob:'**/*.jsx'"
            "glob:'**/*.ts'"
            "glob:'**/*.mts'"
            "glob:'**/*.cts'"
            "glob:'**/*.tsx'"
            "glob:'**/*.vue'"
            "glob:'**/*.svelte'"
            "glob:'**/*.css'"
            "glob:'**/*.scss'"
            "glob:'**/*.less'"
            "glob:'**/*.html'"
            "glob:'**/*.json'"
            "glob:'**/*.jsonc'"
            "glob:'**/*.json5'"
          ];
          # 需要时可再加: '**/*.md' '**/*.mdx' '**/*.graphql'  (YAML 交给下面的 yamlfmt, 二选一)
        };

        # ---------- TOML (taplo, 本机已装) ----------
        # 保留注释, 只做缩进/对齐; 需要时可用 "taplo" "fmt" "--option" ... 传参
        taplo = {
          command = [ "taplo" "fmt" "-" ];
          patterns = [ "glob:'**/*.toml'" ];
        };

        # ---------- Lua (stylua) ----------
        stylua = {
          command = [ "stylua" "--stdin-filepath" "$path" "-" ];
          patterns = [ "glob:'**/*.lua'" ];
        };

        # ---------- Shell (shfmt; 按扩展名自动选 bash/posix/mksh/bats/zsh 方言) ----------
        shfmt = {
          command = [ "shfmt" "--filename" "$path" "-" ];
          patterns = [
            "glob:'**/*.sh'"
            "glob:'**/*.bash'"
            "glob:'**/*.zsh'"
            "glob:'**/*.ksh'"
            "glob:'**/*.mksh'"
            "glob:'**/*.bats'"
          ];
        };

        # fish 脚本: shfmt 不支持 fish, 用 fish 自带的 fish_indent (已装)
        fish-indent = {
          command = [ "fish_indent" ];
          patterns = [ "glob:'**/*.fish'" ];
        };

        # ---------- Nix (nixfmt, RFC 166 风格) ----------
        # 注意: 会把 .nix 按官方风格整体重排; 备选 pkgs.alejandra (nvim.nix 里的 nixpkgs-fmt 已废弃)
        nixfmt = {
          command = [ "nixfmt" "-" ];
          patterns = [ "glob:'**/*.nix'" ];
        };

        # ---------- YAML (yamlfmt) ----------
        # 也可改用 prettier: 把 '**/*.yaml' '**/*.yml' 加进上面的 prettier (二选一, 别同时开)
        yamlfmt = {
          command = [ "yamlfmt" "-" ];
          patterns = [ "glob:'**/*.yaml'" "glob:'**/*.yml'" ];
        };

        # ---------- Go (gofumpt: gofmt 的严格超集) ----------
        # 需要自动增删 import 时另外配 goimports
        gofumpt = {
          command = [ "gofumpt" ];
          patterns = [ "glob:'**/*.go'" ];
        };

        # ---------- Typst (typstyle) ----------
        # 注意: typstyle 默认就读 stdin, 不能传 "-" (会被当成文件路径)
        typstyle = {
          command = [ "typstyle" ];
          patterns = [ "glob:'**/*.typ'" ];
        };

        # ---------- LaTeX (latexindent, 随 texliveFull 已装) ----------
        # 只调缩进/对齐, 不重排正文; 项目可用 .latexindent.yaml 定制
        latexindent = {
          command = [ "latexindent" ];
          patterns = [ "glob:'**/*.tex'" "glob:'**/*.sty'" "glob:'**/*.cls'" "glob:'**/*.ltx'" ];
        };

        # ---------- 可选: 先把包加进 home/dev.nix, 再按同样格式补一条 ----------
        # Haskell:  pkgs.fourmolu / pkgs.stylish-haskell (与 ormolu 二选一, 否则重复格式化)
        # JS 备选:  pkgs.biome / 已装的 deno (deno fmt -)
        # 文档:     '**/*.md' '**/*.mdx' 交给 prettier (它会按 80 列折行)
        # SQL:      pkgs.sqlfluff / pkgs.sql-formatter (必须先确定方言)
      };
      # 用法: jj fix  或  jj fix -s 'reachable(@, mutable())'

      # run = {
      #   jobs = 4;   # jj run 的并行度 (默认 1), 命令行 -j 可覆盖
      # };

      # ======================================================================
      # 14. 其余小节 (按需启用; 全部为 jj 0.45 支持的配置)
      # ======================================================================
      # gerrit = {          # jj gerrit upload 的默认远程/分支, 以及 Link trailer
      #   default-remote = "gerrit";
      #   default-remote-branch = "main";
      #   review-url = "https://review.example.com/project";
      # };

      # split = {
      #   legacy-bookmark-behavior = true;   # (默认) jj split 后书签留在新提交(第二段); false 则留在原提交(第一段)
      # };

      # hints = {          # 各类一次性提示的开关 (0.45 仅有 resolving-conflicts)
      #   resolving-conflicts = true;        # (默认)
      # };

      # "fileset-aliases" = {                # 自定义文件集符号, 用法: jj fix -s rust / jj diff 'rust'
      #   rust = "glob:'**/*.rs'";
      # };

      # "experimental-advance-branches" = {  # 创建新提交时自动前移指定书签 (类似 git 的 main 跟随)
      #   enabled-branches = ["main" "release"];
      #   disabled-branches = ["wip/*"];     # 优先于 enabled-branches
      # };

      # experimental = {
      #   record-predecessors-in-commit = true;  # (默认) 在提交中记录 predecessor 信息 (实验性)
      # };

      # ---- 条件配置 (--scope / --when) -------------------------------------
      # 按仓库路径/工作区/主机名/命令/平台/环境变量覆盖上述任意配置;
      # 等价于"分文件 + --when"写法, 也可放进不受 HM 管理的 ~/.config/jj/conf.d/
      # "--scope" = [
      #   {
      #     "--when".repositories = [ "~/Projects/oss" ];
      #     "--scope".user.email = "oss@example.com";
      #   }
      #   {
      #     "--when".hostnames = [ "hp" ];              # 笔记本上用默认分页器
      #     "--scope".ui.pager = "less -FRXK";
      #   }
      #   {
      #     "--when".platforms = [ "windows" ];
      #     "--scope"."working-copy".eol-conversion = "input-output";
      #   }
      # ];
    };
  };

  # ==========================================================================
  # fix.tools 各命令的可执行文件来源 (依赖包不在本文件安装, 说明见下)
  # --------------------------------------------------------------------------
  #   prettier, stylua, shfmt, nixfmt, yamlfmt, gofumpt, typstyle
  #                        → home/dev.nix (通用开发依赖, 不限于 jj)
  #   ruff                 → home/dev/python.nix
  #   rustfmt              → home/dev/rust.nix
  #   clang-format         → nvim.nix lspDeps (clang-tools, 同时带 clangd)
  #   ormolu, taplo        → nvim.nix lspDeps
  #   fish_indent          → fish 自带 (home/shell/fish.nix)
  #   latexindent          → texliveFull (home/desktop/applications.nix)
  # 注: nvim.nix 里的 prettierd 是给编辑器的常驻服务, 命令行 jj fix 用的是 dev.nix 的 prettier
  # ==========================================================================

  # ==========================================================================
  # delta 集成 (与 git.nix 中 programs.delta.options 的主题/行号设置共用)
  # --------------------------------------------------------------------------
  # HM 的 delta 模块会写入以下 jj 配置:
  #   ui.pager = <delta 可执行文件>
  #   ui.diff-formatter = ":git"                       (delta 需要 git 风格 diff)
  #   merge-tools.delta.diff-expected-exit-codes = [0 1]  (delta 有差异时退出码为 1)
  # 因此上面 ui 段不必重复设置 pager / diff-formatter。
  # 若不想用 delta, 注释掉本行即可回到 jj 默认的 less + :color-words。
  # ==========================================================================
  programs.delta.enableJujutsuIntegration = true;
}
