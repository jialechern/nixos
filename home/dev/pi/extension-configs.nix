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
    # --- 搜索凭据 (与 opencode 的 MCP 共用同一把 key) ---
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

  # pi-permission-system 权限策略 (温和默认):
  #   - 工具与 bash 默认放行 (适配通用助手/系统管理场景)
  #   - 敏感路径 (env/ssh) 全局拒绝, 所有工具与 bash 一视同仁
  #   - 危险 bash 命令: rm -rf / sudo 需确认, mkfs 直接拒绝
  # 文档: https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system
  ".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON {
    permission = {
      "*" = "allow";
      path = {
        "*" = "allow";
        "*.git" = "deny";
        "*.gitignore" = "ask";
        "*.env" = "deny";
        "*.env.*" = "deny";
        "*.env.example" = "allow";
        "~/.ssh/*" = "deny";
      };
      bash = {
        "*" = "allow";
        "rm *" = "ask";
        "git *" = "ask";
        "sudo *" = "ask";
        "mkfs*" = "deny";
      };
    };
  };
}
