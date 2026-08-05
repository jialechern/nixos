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

    # 代码实时反馈 (42K+/mo, MIT): 每次写/编辑后自动跑 LSP 诊断、linter、
    # type-check、格式化建议, 另附 /lens-map 依赖图与 symbol_search
    # 零配置开箱即用; 包较大 (~18MB), 含 ast-grep postinstall 脚本
    "npm:pi-lens"

    # 结构化提问 (43K+/mo, MIT): ask_user_question 工具, 模型拿不准时
    # 以选项式对话框向你确认 (最多 4 问, 支持自填答案), 避免瞎猜
    # 与 rpiv-todo 同作者 (juicesharp); 零配置, 折叠键默认 ctrl+]
    "npm:@juicesharp/rpiv-ask-user-question"

    # 持久记忆 (20K+/mo): 策略驱动的本地记忆 (SQLite FTS5 全文检索) +
    # 会话搜索 + 密钥扫描, 纯本地零依赖零 token
    # 默认仅策略记忆 (不进上下文, 不烧 token), 可用 /hermes 相关命令管理
    "npm:pi-hermes-memory"

    # 权限控制 (31K+/mo, MIT): 对工具/bash/路径/MCP 实施 allow/ask/deny 三级策略
    # 策略文件由 extension-configs.nix 声明式生成
    # (~/.pi/agent/extensions/pi-permission-system/config.json)
    "npm:@gotgenes/pi-permission-system"

    # 多阶段安全审计 (478K+/mo 全站下载第一, MIT): /piolium-* 系列命令
    # 按需触发 (lite/balanced/deep 三种深度), 子代理分阶段审计 + PoC + 报告
    # 注意: 目前为 0.0.x 早期版本, 完整审计可能耗时数小时
    "npm:@vigolium/piolium"

    # 行模式流式输出 (MIT): 给 -p/--print 增加 --stream 标志, 实时输出
    # thinking/文本/工具活动 (无 TUI 无 JSON 包装), 不重复打印最终回复
    # 实现: 拦截 prompt 后 spawn 子进程跑 `pi --mode json -p`, 美化事件流
    # 用法: pi -p "prompt" --stream (非 TTY 时自动激活; 交互模式下为 no-op)
    # 要求 Node >= 22.19.0; 注意: 0.1.0 早期版本 (2026-07-17 发布)
    "npm:pi-print-stream"
  ];
}
