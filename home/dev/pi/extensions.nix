{
  # --- 扩展包资源 (npm/git 包) ---
  # 声明后 pi 首次启动时会自动通过 npm 安装到 ~/.pi/agent/npm/ 并加载
  # (需要网络; 若国内拉取失败, 请配置 npm 镜像或临时注释对应条目)
  packages = [
    # 现代 agent 机制: Codex 风格只读计划模式 (plan-mode, 15K+/mo, MIT)
    # 用法: /plan <prompt> 进入计划模式 → 只读探索/提问 → plan_mode_complete 产出计划
    #       → 选择 implement / export / save。计划模式下编辑/写入被禁, bash 限为只读子集
    # 要求 pi >= 0.80.6 (当前 nixpkgs 0.83.0 满足)
    # 可选配置: ~/.pi/agent/pi-plan-mode.json (默认即可用)
    "npm:@narumitw/pi-plan-mode"

    # 子代理 (社区最热扩展之一, 172K+/mo, MIT): 把任务委托给专注的子会话
    # 内置 agent: scout / researcher / planner / worker / reviewer / oracle / delegate 等
    # 用法: 自然语言 "用 reviewer 审查这个改动", 或 /run /chain /parallel 命令
    # 子代理默认继承当前模型; 调优可加 settings.subagents (如 defaultModel/defaultThinking)
    "npm:pi-subagents"

    # 网页访问 (175K+/mo, MIT): 搜索/抓取/GitHub 克隆/PDF/视频理解
    # 工具: web_search / fetch_content / source_check / get_search_content, 另有 /websearch 交互式策展
    # 搜索 provider 在 ~/.pi/web-search.json 配置 (下方 home.file, 复用 sops 的 Tavily/Firecrawl key)
    # 注意: 与 pi-deepseek-search 的 web_search 工具重名, 二者不要同时安装
    "npm:pi-web-access"

    # 待办清单 (34K+/mo, MIT): todo 工具 + /todos 命令 + 编辑器上方实时面板
    # 清单从会话历史重建, /reload 与上下文压缩后依然保留, 长任务进度一目了然
    # 面板折叠键默认 ctrl+shift+t, 与本配置的 app.session.tree 冲突,
    # 已在 ~/.config/rpiv-todo/config.json 改绑 ctrl+shift+f
    "npm:@juicesharp/rpiv-todo"

    # Context7 文档查询 (Upstash 官方, MIT): resolve-library-id + query-docs 工具
    # 在 pi 请求触发查询上下文文档和最新示例代码
    # 用法: agent 自动调用 (需要 skill 触发) 或 /c7-docs <library> <question>
    # API key 由 pi 包装脚本从 ~/.config/pi/secrets.env 注入 (CONTEXT7_API_KEY)
    "npm:@upstash/context7-pi"
  ];
}
