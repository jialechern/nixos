{
  # =======================================================================
  # MCP 配置参考模板 (全部已禁用)
  #
  # opencode 已将以下功能内建为原生工具, 无需通过 MCP:
  #   context7 → 内置 context7_*       firecrawl → 内置 firecrawl_*
  #   tavily   → 内置 tavily_*         fetch     → 内置 webfetch
  #   memory   → 内置 memory_*         seq-think → 内置 sequential-thinking_*
  #   time     → bash date/curl        fs/git    → 内置 read/write/edit/bash
  #
  # 以下保留典型配置作为未来 MCP 接入的参考模板。
  # =======================================================================

  # ---- 典型模式 1: 本地命令 + API key 环境变量 ----
  # context7 = {
  #   type = "local";
  #   command = [ "context7-mcp" ];
  #   enabled = false;
  #   environment = {
  #     CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
  #   };
  # };

  # ---- 典型模式 2: 同上, 另一个 web 服务的示例 ----
  # firecrawl = {
  #   type = "local";
  #   command = [ "firecrawl-mcp" ];
  #   enabled = false;
  #   environment = {
  #     FIRECRAWL_API_KEY = "{env:FIRECRAWL_API_KEY}";
  #   };
  # };

  # ---- 典型模式 3: 带持久状态的本地命令 ----
  # memory = {
  #   type = "local";
  #   command = [ "mcp-server-memory" ];
  #   enabled = false;
  # };

  # ---- 典型模式 4: 带启动参数的命令 ----
  # git = {
  #   type = "local";
  #   command = [ "mcp-server-git" "--repository" "/path/to/repo" ];
  #   enabled = false;
  # };
}
