{
  # pi-web-access 搜索配置: 复用 sops 注入的 TAVILY_API_KEY / FIRECRAWL_API_KEY
  # $VAR 在请求时解析 (环境变量由 pi 包装脚本从 ~/.config/pi/secrets.env 注入)
  # 文档: https://github.com/nicobailon/pi-web-access (Configuration 一节)
  ".pi/web-search.json".text = builtins.toJSON {
    # Tavily: 主要搜索 provider (与 opencode 的 MCP 共用同一把 key)
    tavilyApiKey = "$TAVILY_API_KEY";
    # Firecrawl: 普通抓取失败时的兜底抽取 (默认缓存优先, 不会主动外发请求)
    firecrawlApiKey = "$FIRECRAWL_API_KEY";
    # 使用 web-search 工具时, 不再请求确认
    workflow = "none";
    # 快捷键: curate (审查搜索结果) 原默认 ctrl+shift+s, 被内置转录搜索占用
    # (见 keybindings.nix 的 tui.altScreen.search), 设为 off 禁用该键;
    # activity 保持默认 ctrl+shift+w
    shortcuts = {
      curate = "off";
    };
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
        "*.env" = "deny";
        "*.env.*" = "deny";
        "*.env.example" = "allow";
        "~/.ssh/*" = "deny";
      };
      bash = {
        "*" = "allow";
        "rm -rf *" = "ask";
        "sudo *" = "ask";
        "mkfs*" = "deny";
      };
    };
  };
}
