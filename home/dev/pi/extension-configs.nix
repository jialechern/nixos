{
  # pi-web-access 搜索配置: 复用 sops 注入的 TAVILY_API_KEY / FIRECRAWL_API_KEY
  # $VAR 在请求时解析 (环境变量由 pi 包装脚本从 ~/.config/pi/secrets.env 注入)
  #
  # ⚠️ 路径: 0.29.0 (2026-09-10) 起默认配置目录改为 pi 的 agent 目录, 即
  # ~/.pi/agent/web-search.json (与本仓库 programs.pi-coding-agent.configDir 一致),
  # 不再回退旧的 ~/.pi/web-search.json。写错路径会被静默忽略 (配置全失效)。
  # 解析顺序 (utils.ts): PI_CODING_AGENT_DIR → $XDG_CONFIG_HOME/pi → ~/.pi/agent
  # 文档: https://github.com/nicobailon/pi-web-access (Configuration 一节)
  ".pi/agent/web-search.json".text = builtins.toJSON {
    # --- 搜索凭据 ---
    # 显式声明凭据来源便于自文档化; 环境变量优先级高于此处的字面值
    tavilyApiKey = "$TAVILY_API_KEY";
    firecrawlApiKey = "$FIRECRAWL_API_KEY";

    # --- 搜索路由 ---
    # 不设 provider (其优先级高于 searchRouting, 会覆盖路由):
    # 先用 Tavily, 失败退 Firecrawl, 再失败退 Exa (无 key 时走托管 MCP,
    # 免凭据兜底; 实测 mcp.exa.ai 可直连)。
    # fallbackOn 决定哪类错误继续尝试下一个 provider; 它不含凭据类错误,
    # 所以 key 配错不会继续回退, 而是就地返回诊断
    searchRouting = {
      providers = [ "tavily" "firecrawl" "exa" ];
      fallbackOn = [ "transient" "quota" "network" "invalid-response" ];
    };

    # --- 交互与快捷键 ---
    # none: web_search 直接返回原始结果, 不弹浏览器策展窗口
    workflow = "none";
    # curate 默认 ctrl+shift+s 与内置转录搜索 (keybindings.nix 的
    # tui.altScreen.search) 撞键; pi 核心的冲突检测里该内置键不在保留白名单,
    # 扩展会胜出并告警, 故把 curate 让到空闲键 ctrl+shift+u。
    # activity (活动监控) 保持默认 ctrl+shift+w
    shortcuts = {
      curate = "ctrl+shift+u";
      activity = "ctrl+shift+w";
    };

    # --- 工具 / 命令 / 图片开关 (显式写出, 便于日后核对) ---
    tools = {
      webSearch = { enabled = true; };
      sourceCheck = { enabled = true; };
      fetchContent = { enabled = true; };
      getSearchContent = { enabled = true; };
    };
    commands = {
      websearch = { enabled = true; };
      curator = { enabled = true; };
      search = { enabled = true; };
      "google-account" = { enabled = true; };
    };
    image = { enabled = true; };

    # --- 内容提取 ---
    # fetch_content 内联切片, 同时是 get_search_content 的默认/最大切片
    maxInlineContentChars = 30000;
    fetch = { timeout = 30; };
    # 无 Datalab / Gemini key, auto 会落到本地 unpdf (纯文本, 离线免费)
    pdf = {
      provider = "auto";
      maxSizeMB = 20;
      maxPages = 100;
    };

    # --- GitHub ---
    # 公共库直接 clone 到本地; 超过 350MB 走 API 轻量视图
    # gh CLI 由 pi.nix 的 extraPackages 提供, 认证靠 sops.nix 注入的 GH_TOKEN;
    # 未认证或 gh 失败时 PR/Issue 降级到未认证 REST (仅公共库, 限流 60/h, 无 checks)
    githubClone = {
      enabled = true;
      maxRepoSizeMB = 350;
      cloneTimeoutSeconds = 30;
    };
    githubPrIssue = { enabled = true; };

    # --- 视频 ---
    # 无 GEMINI_API_KEY / Gemini Web cookie / Perplexity key 时, YouTube 与本地视频
    # 分析都会失败, 但 enabled = true 会返回明确可操作的报错
    # ("Sign into Google ... or set GEMINI_API_KEY"), 优于静默退化成普通网页抓取。
    # 注意: 本地视频抽帧受 video.enabled 门控; YouTube 抽帧只受 image.enabled 门控,
    # 用 yt-dlp + ffmpeg 本地完成, 不需要 API key。
    youtube = { enabled = true; };
    video = { enabled = true; };

    # --- SSRF ---
    # 保持默认为空: 本机 v2raya 未使用 TUN/fake-IP (公共域名解析到真实 IP),
    # 无需豁免 198.18.0.0/15 等保留段; 保留完整 SSRF 防护
  };

  # rpiv-todo 配置: 折叠面板的快捷键
  # 绑定 ctrl+shift+f; 该键与内置 tui.altScreen.search 冲突,
  # 后者已在 keybindings.nix 改绑到 ctrl+shift+s
  # 文档: https://github.com/juicesharp/rpiv-mono/tree/main/packages/rpiv-todo
  ".config/rpiv-todo/config.json".text = builtins.toJSON {
    collapseKey = "ctrl+shift+f";
  };

  # pi-open-tui 配置 (TUI 界面扩展: header / footer / 圆角编辑器 / 轮次遥测 / thinking peek)
  #
  # 路径由插件源码的 getConfigPath() 决定: join(getAgentDir(), "open-tui.json"),
  # 即 ~/.pi/agent/open-tui.json (跟随 PI_CODING_AGENT_DIR), 与 programs.pi-coding-agent
  # 的 configDir 一致。
  #
  # 重要: 该文件被本仓库声明后是指向 nix store 的只读符号链接, 而插件的 saveConfig()
  # 是 best-effort 且静默吞掉写入异常 (catch {}), 所以:
  #   - 读取不受影响: ensureConfigExists 见文件已存在即返回, 不会尝试创建
  #   - 但 /open-tui 里改的任何设置都不会落盘, 只在当前会话内存里生效、重启即失
  # 改配置的正确方式是改这里再 rebuild; 想交互式调参就先注释掉本段。
  #
  # 下面的键按插件 0.3.6 的 OpenTuiConfig / DEFAULT_CONFIG 全部显式写出 (插件用
  # deepMerge 合并, 允许只写部分键; 写全便于日后对照与审计)。
  # 又: GitHub main 的 README 还提到 hostname 分段, 那是未发布的功能 ——
  # 0.3.6 的 FooterSegments 接口里没有该字段, 写了会被忽略, 故不写。
  ".pi/agent/open-tui.json".text = builtins.toJSON {
    # 总开关
    enabled = true;

    # /open-tui 设置界面的语言 (en | zh)
    settingsLanguage = "zh";

    # 光标样式 (block | bar | underline)。本机 kitty 的 cursor_shape = "block",
    # 保持一致; bar / underline 需终端支持光标形状切换。
    cursorStyle = "block";

    # 全屏模式下鼠标滚轮每格滚动行数, 取值 1-10 (超出会被 clamp)。
    # 实现上是 Reflect.set 写 pi 的私有字段 tui.wheelScrollLines (注释标明针对
    # pi 0.84.2); 当前 pi 0.85.1 若不兼容会自动降级为 pi 默认值, 只是该项无效,
    # 不会报错。
    fullscreen = {
      wheelScrollLines = 4;
    };

    # 图标集 (auto | nerd | ascii)。auto 走 detectNerdFont(): 识别 TERM=xterm-kitty
    # → nerd (本机 kitty 已配 JetBrainsMono Nerd Font Mono), 同时 ssh 到其它终端时
    # 会自行退化为 ascii, 所以保留 auto 比硬写 nerd 更稳。
    icons = {
      mode = "auto";
    };

    # footer 分段开关。显示顺序由 footer.ts 固定 (cwd → sessionName → git 段 →
    # runtime → context → tokens → cost → 扩展状态), 本对象只管开关;
    # 且 footer 自带 compact/drop 逻辑, 横向不足时会自动舍弃右侧分段。
    # 沿用插件默认: 关掉 sessionName 与 gitCommit 两个低频项。
    # 若仍嫌拥挤可继续关 cost / tokens; 关 extensionStatuses 会连 MCP 状态一起隐藏。
    footerSegments = {
      cwd = true;
      sessionName = false;
      gitBranch = true;
      gitStatus = true;
      gitCommit = false;
      runtime = true;
      context = true;
      tokens = true;
      cost = true;
      extensionStatuses = true;
    };

    # 每轮结束后的遥测行: TPS / TTFT / 耗时 / tokens / stall 次数 / 牌价速率。
    # 注意 cost 是模型牌价单价 (usage.cost.total), 不是会话累计花费 —— 后者在 footer。
    telemetry = {
      enabled = true;
      tps = true;
      ttft = true;
      duration = true;
      tokens = true;
      stalls = true;
      cost = true;
    };

    # pi 开启"隐藏思考"时, 用动态 ticker 替换静止的 "Thinking..." 标签。
    # 取值 0=关闭 | 1 | 2 行 (其它值回落到默认 1); 仅在模型真的流出思考内容时出现。
    thinkingPeek = {
      lines = 1;
    };
  };

  # pi-permission-system 权限策略 (温和默认 + 密钥保护):
  #   - 工具与 bash 默认放行 (适配通用助手/系统管理场景)
  #   - 密钥与凭据路径一律 deny (deny 是硬拒绝、不弹窗、运行时无法放行)
  #   - .env 按方向区分: 读 deny (密钥不入上下文与日志), 写 ask (仍可批准修改)
  #   - .git 只拦写 (含 .git 目录本身与其中内容), 读 .git 仍可用于查看仓库状态
  #     (旧配置的裸 path "*.git" = deny 会连读一起拒, 实测误杀了 ls -d .git / git remote -v)
  #   - cwd 之外: 读显式放行, 只拦写 (实测该 surface 缺省即 ask, 读 /nix/store 弹窗很多)
  #   - 危险 bash 命令: rm 递归删除 / sudo 需确认, mkfs 直接拒绝
  #   - git: 只放行只读子命令 (status/diff/log/rev-parse 等), 其余一律询问
  #
  # 三条影响写法的语义 (详见上游 docs/configuration.md):
  #   1. path / external_directory 是 path_read+path_write 的语法糖, 想"只拦写"必须用方向键
  #   2. 同一 surface 内 last-match-wins —— 宽泛规则在前, 具体例外在后
  #   3. 显式方向键会追加在糖展开的条目之后, 因此一定覆盖裸键的规则
  #   4. Nix 属性集无序, builtins.toJSON 按属性名排序输出 —— 而该扩展靠 JSON 键序实现
  #      last-match-wins。即规则的实际生效顺序由字母序决定, 不由你写代码的先后决定:
  #      `*` 排在 `~` 之前, 所以"宽泛 * 在前、具体 ~ 例外在后"恰好总是成立;
  #      但若想要某个 `*` 开头的 allow 覆盖 `~` 开头的 deny, 这条会反过来坑你。
  #      本例中 `*.env.example` 的 allow 能胜过 `*.env.*` 的 deny, 正是因为它按字母序在后。
  #
  # 对话框键位保持默认 y/s/b/n/r (未启用 permissionDialogKeys 的数字键位)。
  # 注意: 中文输入法组字时字母键会被候选框吞掉, 而退出候选框的 esc 会被对话框读作
  # "拒绝" —— 遇到对话框看似无响应时, 先切到英文输入状态再按。
  # 文档: https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system
  ".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON {
    permission = {
      "*" = "allow";
      # 通用黑名单: 对所有工具与 bash 生效, 读写一视同仁
      path = {
        "*" = "allow";
        "~/.ssh/*" = "deny";
        # 密钥与凭据 (deny = 硬拒绝): sops age 私钥是其中最关键的一把,
        # 它能解开 secrets/ 下的全部密钥
        "~/.config/sops/age/*" = "deny";
        "~/.gnupg/*" = "deny";
        "~/.config/gh/*" = "deny"; # GH_TOKEN
        "~/.aws/*" = "deny";
        "~/.docker/*" = "deny";
        "~/.kube/*" = "deny";
        "*.npmrc" = "deny"; # 可能含 registry token
        "*.netrc" = "deny";
        "*.git-credentials" = "deny";
      };
      # 读: env 文件一律拒绝 (密钥一旦读进上下文就留在会话历史与 review log 里,
      # 事后改规则也收不回); 模板放行
      path_read = {
        "*.env" = "deny";
        "*.env.*" = "deny";
        "*.env.example" = "allow";
      };
      # 写: .git 只拦写以保护仓库元数据 —— 目录本身与其内容都要拦,
      # 否则 rm -rf .git 这类命令的方向不确定 (rm 不是纯读命令, 会查两个方向),
      # 只写 "*.git/*" 会漏掉裸 .git; env 仍需确认 (允许 agent 协助修改)
      path_write = {
        "*.git" = "deny";
        "*.git/*" = "deny";
        "*.env" = "ask";
        "*.env.*" = "ask";
      };
      # cwd 边界: 只拦写 —— 挡住误改 ~/.bashrc / 其它项目
      # 注意: 该 surface 缺省就是 ask (实测产生 1236 次请求, 多为读 /nix/store 与 ~/.pi),
      # 所以"读不打扰"必须显式写 allow, 不配置反而会弹窗; Pi 自身的
      # Infrastructure Read Auto-Allow 只覆盖 read/find/grep/ls 工具, 不覆盖 bash。
      external_directory_read = {
        "*" = "allow";
      };
      external_directory_write = {
        "*" = "ask";
        "/tmp/*" = "allow"; # 临时目录是常规草稿区
      };
      bash = {
        "*" = "allow";
        # rm: 只拦递归删除 (对齐 AGENTS.md 的"rm -rf 先说明影响再确认"), 单文件 rm 不打扰。
        # 变体写法多, 逐个列举易漏: 已知未覆盖的还有长选项在前再接 -rf 的写法
        # (如 rm --no-preserve-root -rf /), 以及把 -r 写在操作数之后的写法。
        "rm -r*" = "ask";
        "rm -R*" = "ask";
        "rm --recursive*" = "ask";
        "rm --force --recursive*" = "ask";
        # --- git: 只读子命令放行, 其余一律询问 ---------------------------------
        # 对齐 AGENTS.md 的"不擅自做 git 操作": 兜底 ask, 白名单放行只读形式。
        # 实测 "git *" = ask 产生了 368 次请求 (status 97 / diff 84 / log 35 / rev-parse 27),
        # 其中绝大多数是只读查询。
        # 字母序约束: `*` (0x2A) 小于任何字母, 所以 "git *" 必然排在所有
        # "git <子命令> ..." 之前; 下面每条白名单都排在它之后, 因此能覆盖它。
        "git *" = "ask";

        # 纯只读子命令 (不存在变更形式), 整条放行
        "git status *" = "allow";
        "git diff *" = "allow";
        "git log *" = "allow";
        "git show *" = "allow";
        "git rev-parse *" = "allow";
        "git rev-list *" = "allow";
        "git describe *" = "allow";
        "git grep *" = "allow";
        "git blame *" = "allow";
        "git ls-files *" = "allow";
        "git ls-tree *" = "allow";
        "git ls-remote *" = "allow";
        "git merge-base *" = "allow";
        "git shortlog *" = "allow";

        # 混合型子命令: 只放行列举/查询形式, 变更形式落回上面的 "git *" 询问。
        # 短选项用 -x* (而非 -x *) 以覆盖 -av/-vv 这类合并写法;
        # branch 只放行 a/r/v 三个列举标志, 变更标志 (-d -D -m -M -c -C -f -u -t)
        # 都不以它们开头。未列出但只读的写法 (如 git config user.name) 会询问一次,
        # 确认后被会话记住; 需要常用时按同样格式补一行即可。
        "git branch -a*" = "allow";
        "git branch -r*" = "allow";
        "git branch -v*" = "allow";
        "git branch --list*" = "allow";
        "git branch --show-current*" = "allow";
        "git config --get*" = "allow";
        "git config --list*" = "allow";
        "git remote -v*" = "allow";
        "git remote show*" = "allow";
        "git reflog" = "allow";
        "git reflog show*" = "allow";
        "git stash list*" = "allow";
        "git tag -l*" = "allow";
        "git tag --list*" = "allow";
        "git worktree list*" = "allow";
        "sudo *" = "ask";
        "mkfs*" = "deny";
      };
    };
  };
}
