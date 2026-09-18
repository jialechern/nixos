{ config, pkgs, lib, ... }:

let
  # ---------------------------------------------------------------------------
  # pi 配置目录
  # pi 配置根目录: 与上游 CLI 默认值 ~/.pi/agent 一致
  # 显式写出 (而非依赖模块默认值), 防止上游将来变更默认路径影响本配置
  # ---------------------------------------------------------------------------
  piConfigDir = "${config.home.homeDirectory}/.pi/agent";

  # ---------------------------------------------------------------------------
  # pi 项目级扩展集合 (--local)
  #
  # 这些包不进全局 settings.packages, 因此未装配它们的项目是零启动成本;
  # 在项目目录内运行 pi-init / pi-coding 即可装配到该项目的 .pi/settings.json。
  # ---------------------------------------------------------------------------

  # 全局扩展集合: 被 nix 声明式管理, 是 pi 扩展出的最基础的能力
  # 声明后 pi 首次启动时会自动通过 npm 安装到 ~/.pi/agent/npm/ 并加载
  # (需要网络; 若国内拉取失败, 请配置 npm 镜像或临时注释对应条目)
  globalExtensions = [
    # 权限控制 (MIT, gotgenes): 对工具 / bash / 路径 / MCP 实施 allow / ask / deny 三级策略
    # 策略文件: ~/.pi/agent/extensions/pi-permission-system/config.json (见下方 home.file)
    "npm:@gotgenes/pi-permission-system"
    # 待办清单 (MIT, juicesharp): todo 工具 + /todos 命令 + 编辑器上方实时面板
    # 面板折叠键在 ~/.config/rpiv-todo/config.json 绑定为 ctrl+shift+f
    # (该键与内置 tui.altScreen.search 冲突, 后者已在上方 keybindings 改绑 ctrl+shift+s)
    "npm:@juicesharp/rpiv-todo"
    # 结构化提问 (MIT, juicesharp): ask_user_question 工具, 模型拿不准时以选项式对话框向你确认
    "npm:@juicesharp/rpiv-ask-user-question"
    # 自主目标模式 (MIT, narumitw): 给 pi 一个会话级目标, 让它持续工作直到完成/暂停/等待/触达安全上限
    "npm:@narumitw/pi-goal"
    # Codex 风格只读规划模式 (MIT, narumitw): pi 核心未内置 plan mode, 此扩展补上
    "npm:@narumitw/pi-plan-mode"
    # TUI 界面扩展 (MIT, OldSuns): header / footer / 圆角编辑器 / 轮次遥测 / thinking peek
    # 配置见下方 home.file 的 ~/.pi/agent/open-tui.json
    # 注意: 这是 UI 接管型扩展, 会重写编辑器边框与上下区域, 与上面的 rpiv-todo
    # 面板 (编辑器上方实时面板) 存在潜在重叠; 若显示异常可调整本数组的先后顺序
    "npm:pi-open-tui"
  ];

  # 基础集合 (pi-init): 通用能力, 任何项目都可能想要
  localBaseExtensions = [
    # 网页访问: 搜索 / 抓取 / GitHub 克隆 / PDF / 视频理解
    # 配置见下方 home.file 的 ~/.pi/agent/web-search.json
    "npm:pi-web-access"
    # 子代理: 把任务委托给专注的子会话
    "npm:pi-subagents"
    # 持久记忆 + 会话搜索 + 密钥扫描
    "npm:pi-hermes-memory"
  ];

  # 编码集合 (pi-coding): 与基础集合正交, 只含编码相关
  # 装配是幂等追加, 两组叠加即得并集: 日常项目跑 pi-init 即可,
  # 编码项目再叠加 pi-coding, 主动用启动耗时换功能。
  # 需要继续细化时可再加一组 (如 localAuditExtensions → pi-audit)。
  localCodingExtensions = [
    # 实时代码反馈 (LSP 诊断 / linter / autofix)
    "npm:pi-lens"
    # 官方 Context7 扩展 (MIT, Upstash): 给 agent 注入最新的库文档 (不依赖训练数据)
    "npm:@upstash/context7-pi"
  ];

  # ---------------------------------------------------------------------------
  # 项目级扩展集合的装配与清理逻辑见 ./pi/pi-local-exts.sh
  # (由 home.nix 部署到 ~/.local/bin), 包列表由下面的别名传入。
  #
  # 语义是"幂等追加": 各别名只往当前项目追加自己那组包, 不卸载任何东西。
  # 所以依次运行多个别名得到的是它们的并集 —— 日常项目只跑 pi-init 保持轻量,
  # 复杂项目再叠加 pi-coding, 主动用启动耗时换功能。要回退用 pi-clean。
  # 注: --local 装配要求项目已被信任 (pi 的 trust 机制), 否则 pi install 会拒绝。
  #
  # 用 `sh <固定路径>` 调用, 既不依赖执行位, 也不会把会随内容变化的 store 路径写进别名。
  # ---------------------------------------------------------------------------
  piLocalExts = "sh ${config.home.homeDirectory}/.local/bin/pi-local-exts";
in
{
  programs.pi-coding-agent = {
    # 必须启用才会安装软件包并生成配置
    enable = true;

    # 使用包装过后的软件包: 启动时加载 sops 生成的密钥文件
    # 密钥由 sops.nix 的 "pi-secrets.env" 模板生成, 文件不存在时静默跳过
    package = pkgs.symlinkJoin {
      name = "pi-coding-agent-wrapped";
      paths = [ pkgs.pi-coding-agent ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pi \
          --run '
            SECRET_FILE="$HOME/.config/pi/secrets.env"
            if [ -f "$SECRET_FILE" ]; then
              set -a
              source "$SECRET_FILE"
              set +a
            fi
          '
      '';
    };

    # 扩展包运行时依赖: pi install npm:... 安装扩展 (如 @termdraw/pi) 需要 npm 与 bun
    # gh: pi-web-access 的 GitHub 能力 (PR/Issue 富字段视图、私有库、超大仓库 API 路径)
    #     注: gh 不读 .netrc, 认证靠 sops.nix 注入 pi 进程的 GH_TOKEN
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
      pkgs.gh
    ];

    # 配置目录 (见文件头"一")
    configDir = piConfigDir;

    # -------------------------------------------------------------------------
    # pi 快捷键 (keybindings.json)
    # -------------------------------------------------------------------------
    keybindings = {
      # --- 输入 ---
      "tui.input.newLine" = [ "shift+enter" "ctrl+j" ]; # 插入换行
      "tui.input.submit" = "enter"; # 提交输入
      "tui.input.tab" = "tab"; # Tab / 自动补全

      # --- 选择列表 (模型选择器 /model、会话恢复等通用列表) ---
      # 注意: /resume (pi -r) 的会话选择器里, app.session.togglePath (默认
      # ctrl+p) 与 app.session.toggleNamedFilter (默认 ctrl+n) 的匹配优先于
      # tui.select.*, 会抢走这两个键。因此下面必须把这两个会话选择器专用键
      # 换绑, ctrl+p / ctrl+n 才能作为上下移动使用 (已在下方处理)。
      "tui.select.up" = [ "up" "ctrl+p" ]; # 上移
      "tui.select.down" = [ "down" "ctrl+n" ]; # 下移
      "tui.select.confirm" = "enter"; # 确认选择
      "tui.select.cancel" = [ "escape" ]; # 取消选择

      # --- 转录搜索 (全屏/滚动视口) ---
      # 内置默认 ctrl+shift+f 被 rpiv-todo 的面板折叠键占用 (见下方 web-search.json
      # 之后那段 rpiv-todo 配置), 改绑到 ctrl+shift+s; 该键原为 pi-web-access 的
      # curate 快捷键, 已在下方 web-search.json 的生成配置中把 curate 改绑到空闲键
      # ctrl+shift+u (旧写法 shortcuts.curate = "off" 不是官方支持语义)
      "tui.altScreen.search" = "ctrl+shift+s"; # 搜索转录内容

      # --- 应用操作 ---
      # 会话选择器专用键: 原默认 ctrl+p (切换路径显示) / ctrl+n (仅命名会话过滤)
      # 与 tui.select.up/down 冲突, 换绑到 ctrl+shift+p / ctrl+shift+n
      # (两者当前均空闲; 如需完全禁用可改为 [])
      "app.session.togglePath" = "ctrl+."; # 切换路径显示
      "app.session.toggleNamedFilter" = "ctrl+,"; # 仅显示命名会话
      "app.interrupt" = "escape"; # 取消/中止
      "app.exit" = "ctrl+q"; # 退出 (输入为空时)
      "app.model.cycleForward" = "ctrl+\\"; # 循环到下一个模型
      "app.model.cycleBackward" = "ctrl+shift+\\"; # 循环到上一个模型
      "app.thinking.cycle" = "shift+tab"; # 循环思考等级
      "app.thinking.toggle" = "ctrl+f"; # 折叠/展开思考块
      # "app.message.copy" = "ctrl+x"; # 复制最后一条助手消息
      "app.message.followUp" = "ctrl+enter"; # 排队跟进消息
      "app.message.dequeue" = "ctrl+up"; # 撤回排队消息到输入框
    };

    # -------------------------------------------------------------------------
    # 自定义模型 (models.json)
    # 当前 providers 为空 (下面的配置样例整段被注释掉了); 保留以备 pi.dev 远程目录
    # 尚未收录某个新模型时启用。
    # -------------------------------------------------------------------------
    models = {
      providers = {
        # ===================================================================
        # DeepSeek 官方 API
        # 认证: auth 由 /login deepseek 写入 ~/.pi/agent/auth.json, 故不写 apiKey
        # base_url: https://api.deepseek.com (OpenAI 兼容)
        # ===================================================================
        # deepseek = {
        #   baseUrl = "https://api.deepseek.com";
        #   api = "openai-completions";
        # 
        #   models = [
        #     # --- deepseek-flash (2026-09-10 上线, 即 V4.1 Flash 的正式 API 名称) ---
        #     # 线上 /models 目前只返回 deepseek-flash 与 deepseek-v4-pro 两项, 旧名
        #     # deepseek-v4-flash 与内测 ID deepseek-v4.1-flash-expires-on-0910 均被
        #     # 重定向到同一后端; 该模型原生多模态 (实测可读图)。
        #     # 官方文档与 pi.dev 远程目录尚未收录, 故在此本地补齐。
        #     # 上下文 / 输出上限沿用同 provider 内置条目公布的 1M / 384K: 新模型尚未
        #     # 被官方价格页收录, 无更权威数值可依。不填 cost —— 单价未公布, 留空
        #     # 好过按 V4-Flash 旧价误导显示。
        #     {
        #       id = "deepseek-flash";
        #       name = "DeepSeek Flash (V4.1)";
        #       reasoning = true;
        #       input = [ "text" "image" ]; # 原生多模态
        #       contextWindow = 1000000;
        #       maxTokens = 384000;
        #       # 官方仅支持 low / high / max 三档, 其余置 null 从 UI 中隐藏;
        #       # 关闭思考交由 thinkingFormat = "deepseek" 发送 thinking.type = "disabled"
        #       # 实现 (2026-09-10 实测该模型支持)。
        #       thinkingLevelMap = {
        #         "minimal" = null;
        #         "low" = "low";
        #         "medium" = null;
        #         "high" = "high";
        #         "xhigh" = null;
        #         "max" = "max";
        #       };
        #       # compat 与内置 deepseek 条目保持一致
        #       compat = {
        #         supportsStore = false;
        #         supportsDeveloperRole = false;
        #         maxTokensField = "max_tokens";
        #         requiresReasoningContentOnAssistantMessages = true;
        #         thinkingFormat = "deepseek";
        #       };
        #     }
        #   ];
        # };
      };
    };

    # -------------------------------------------------------------------------
    # pi 全局设置 (settings.json, 含全局扩展包)
    # -------------------------------------------------------------------------
    settings = {
      # --- 模型与思考 ---
      defaultProvider = "deepseek"; # 默认提供商
      defaultModel = "deepseek-flash"; # 默认模型
      defaultThinkingLevel = "high"; # 默认思考等级

      # --- UI 与显示 ---
      theme = "catppuccin-mocha-mauve"; # 自定义 Catppuccin Mocha (mauve 强调色) 主题

      # --- 自动压缩 (官方文档示例推荐值) ---
      compaction = {
        enabled = true;
        reserveTokens = 16384; # 为 LLM 回复预留的 token
        keepRecentTokens = 20000; # 保留不摘要的最近 token
      };

      # --- 重试 (官方文档示例推荐值) ---
      retry = {
        enabled = true;
        maxRetries = 3;
      };

      # --- 网络代理 (可选) ---
      # 国内访问海外 API (如 OpenCode Zen/Go ...) 时启用, 走本机代理 127.0.0.1:20172
      # pi 会将其应用为 HTTP_PROXY / HTTPS_PROXY (仅全局设置, 项目设置可覆盖)
      # httpProxy = "http://127.0.0.1:20172";

      # --- 全局扩展包 ---
      packages = globalExtensions;
    };

    # -------------------------------------------------------------------------
    # AGENTS.md: 全局上下文 (作用于所有项目)
    # 文档: https://pi.dev/docs/latest/quickstart (Give pi project instructions)
    # 修改后需 /reload 或重启生效
    # -------------------------------------------------------------------------
    context = ./pi/AGENTS.md;
  };

  # ---------------------------------------------------------------------------
  # home.file: 主题 / 提示词模板 / 各扩展配置
  # 注: 凡是用 builtins.toJSON 生成的 json, 都是"声明式只读"的 —— 指向 nix store
  # 的符号链接, 在 pi 内改这些配置不会落盘, 改配置请改本文件后 rebuild。
  # ---------------------------------------------------------------------------
  home.file = {
    # --- 自定义主题 (Catppuccin Mocha mauve) ---
    "${piConfigDir}/themes/catppuccin-mocha-mauve.json".source =
      ./pi/catppuccin-mocha-mauve.json;

    # --- 提示词模板 (/init) ---
    "${piConfigDir}/prompts/init.md".source = ./pi/prompts/init.md;

    # pi-web-access 搜索配置: 复用 sops 注入的 TAVILY_API_KEY / FIRECRAWL_API_KEY
    # $VAR 在请求时解析 (环境变量由 pi 包装脚本从 ~/.config/pi/secrets.env 注入)
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
      # curate 默认 ctrl+shift+s 与内置转录搜索 (上方 keybindings 的
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
      # gh CLI 由本文件 programs.pi-coding-agent.extraPackages 提供,
      # 认证靠 sops.nix 注入的 GH_TOKEN;
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
    # 后者已在上方 keybindings 改绑到 ctrl+shift+s
    # 文档: https://github.com/juicesharp/rpiv-mono/tree/main/packages/rpiv-todo
    ".config/rpiv-todo/config.json".text = builtins.toJSON {
      collapseKey = "ctrl+shift+f";
    };

    # pi-open-tui 配置 (TUI 界面扩展: header / footer / 圆角编辑器 / 轮次遥测 / thinking peek)
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
  };

  # ---------------------------------------------------------------------------
  # shell 别名
  # ---------------------------------------------------------------------------
  home.shellAliases = {
    ag = "pi";

    # pi-init: 把"基础扩展集合"追加到当前项目 (.pi/settings.json)
    "pi-init" = "${piLocalExts} install ${lib.concatStringsSep " " localBaseExtensions}";

    # pi-coding: 把"编码扩展集合"追加到当前项目 (与 pi-init 叠加, 幂等)
    "pi-coding" = "${piLocalExts} install ${lib.concatStringsSep " " localCodingExtensions}";

    # pi-clean: 卸载当前项目全部 --local 扩展, 并清理 ~/.pi/agent/npm 的全局残留
    "pi-clean" = "${piLocalExts} clean";
  };
}
