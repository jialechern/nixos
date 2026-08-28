{
  # --- 扩展包资源 (npm/git 包) ---
  # 声明后 pi 首次启动时会自动通过 npm 安装到 ~/.pi/agent/npm/ 并加载
  # (需要网络; 若国内拉取失败, 请配置 npm 镜像或临时注释对应条目)
  packages = [
    # 子代理: 把任务委托给专注的子会话
    # 内置 agent: scout / researcher / planner / worker / reviewer / oracle / delegate 等
    # 用法: 自然语言 "用 reviewer 审查这个改动", 或 /run /chain /parallel 命令
    # 子代理默认继承当前模型; 调优可加 settings.subagents (如 defaultModel/defaultThinking)
    "npm:pi-subagents"

    # 网页访问: 搜索/抓取/GitHub 克隆/PDF/视频理解
    # 工具: web_search / fetch_content / source_check / get_search_content, 另有 /websearch 交互式策展
    # 搜索 provider 在 ~/.pi/web-search.json 配置 (下方 home.file, 复用 sops 的 Tavily/Firecrawl key)
    # 注意: 与 pi-deepseek-search 的 web_search 工具重名, 二者不要同时安装
    "npm:pi-web-access"

    # 待办清单: todo 工具 + /todos 命令 + 编辑器上方实时面板
    # 清单从会话历史重建, /reload 与上下文压缩后依然保留, 长任务进度一目了然
    # 面板折叠键在 ~/.config/rpiv-todo/config.json 绑定为 ctrl+shift+f
    # (该键与内置 tui.altScreen.search 冲突, 后者已在 keybindings.nix 改绑 ctrl+shift+h)
    "npm:@juicesharp/rpiv-todo"

    # 结构化提问 (43K+/mo, MIT): ask_user_question 工具, 模型拿不准时
    # 以选项式对话框向你确认 (最多 4 问, 支持自填答案), 避免瞎猜
    # 与 rpiv-todo 同作者 (juicesharp); 零配置, 折叠键默认 ctrl+]
    "npm:@juicesharp/rpiv-ask-user-question"

    # 权限控制 (31K+/mo, MIT): 对工具/bash/路径/MCP 实施 allow/ask/deny 三级策略
    # 策略文件由 extension-configs.nix 声明式生成
    # (~/.pi/agent/extensions/pi-permission-system/config.json)
    "npm:@gotgenes/pi-permission-system"

    # 持久后台任务 (26K+/mo, ISC): 后台跑长命令 / 只读子代理调查 / 多模型 Fusion
    # /bg 启动即返回, 完成时 footer 通知; bg_delegate 上下文感知的只读调查代理
    # 注意: 需 Node >= 22.19.0; 任务非沙箱 (等同普通 shell 权限); Shift+↓ 打开任务栏
    "npm:pi-background-tasks"
  ];
}
