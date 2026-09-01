{
  # --- 扩展包资源 (npm/git 包) ---
  # 声明后 pi 首次启动时会自动通过 npm 安装到 ~/.pi/agent/npm/ 并加载
  # (需要网络; 若国内拉取失败, 请配置 npm 镜像或临时注释对应条目)
  packages = [
    # 子代理: 把任务委托给专注的子会话
    # 用法: 自然语言 "用 reviewer 审查这个改动", 或 /run /chain /parallel
    # 内置 agent: scout / researcher / planner / worker / reviewer / oracle / delegate 等
    # 子代理默认继承当前模型; 调优可加 settings.subagents (如 defaultModel/defaultThinking)
    "npm:pi-subagents"

    # 网页访问: 搜索 / 抓取 / GitHub 克隆 / PDF / 视频理解
    # 工具: web_search / fetch_content / source_check / get_search_content, 另有 /websearch 交互式策展
    # 搜索 provider 由 extension-configs.nix 生成 (~/.pi/web-search.json, 复用 sops 的 Tavily/Firecrawl key)
    # 注意: 与 pi-deepseek-search 的 web_search 工具重名, 二者不要同时安装
    "npm:pi-web-access"

    # 待办清单 (MIT, juicesharp): todo 工具 + /todos 命令 + 编辑器上方实时面板
    # 列表从会话历史重建, /reload 与压缩后依然保留, 无磁盘写入; 支持 blockedBy 依赖排序
    # 用法: 直接让模型"把任务拆成 todos" 即可; /todos 随时查看全量列表
    # 面板折叠键在 ~/.config/rpiv-todo/config.json 绑定为 ctrl+shift+f
    # (该键与内置 tui.altScreen.search 冲突, 后者已在 keybindings.nix 改绑 ctrl+shift+h)
    "npm:@juicesharp/rpiv-todo"

    # 结构化提问 (MIT, juicesharp): ask_user_question 工具, 模型拿不准时以选项式对话框向你确认
    # 最多 4 问 / 次; 按键: ↑↓ 选择, Enter 确认, Tab 切换问题, n 给回答加备注, Esc 放弃
    # 零配置; 非交互会话自动隐藏该工具; 折叠键默认 ctrl+]
    "npm:@juicesharp/rpiv-ask-user-question"

    # 权限控制 (MIT, gotgenes): 对工具 / bash / 路径 / MCP 实施 allow / ask / deny 三级策略
    # 当前策略 (extension-configs.nix 生成): 默认放行; .env / ~/.ssh 拒绝; rm -rf / sudo / git ask; mkfs 拒绝
    # 交互确认按键: y 批准, s 本次会话批准, n 拒绝; 项目级配置需目录受信任才生效
    # 策略文件: ~/.pi/agent/extensions/pi-permission-system/config.json
    "npm:@gotgenes/pi-permission-system"

    # 持久后台任务 (ISC): 后台跑长命令 / 只读子代理调查 / 多模型 Fusion
    # 用法: /bg <命令> 启动即返回, 完成时 footer 通知; Shift+↓ 打开任务栏
    # bg_delegate = 上下文感知的只读调查代理; 任务非沙箱 (等同普通 shell 权限)
    # 注意: 需 Node >= 22.19.0
    "npm:pi-background-tasks"

    # Codex 风格只读规划模式 (MIT, narumitw): pi 核心未内置 plan mode, 此扩展补上
    # /plan (或 /plan start /plan <问题>) 进入只读协作模式: 探索代码库、澄清疑问、产出可执行的实现计划,
    # 计划获批前不允许任何文件修改, 适合大改动前先对齐方案
    # 与下方 pi-goal 同作者, 二者可共存 (共享协作互斥锁)
    "npm:@narumitw/pi-plan-mode"

    # 自主目标模式 (MIT, narumitw): 给 pi 一个会话级目标, 让它持续工作直到完成/暂停/等待/触达安全上限
    # /goal 启动目标模式; 配套工具 goal_complete({goal_id, summary}) 声明完成,
    # goal_blocked({goal_id, reason, evidence}) 声明卡住 (附证据与重试次数), goal_wait 等待外部事件
    # 适合"把这个任务做完再停"的长跑场景; 另有可选实验性有序队列
    "npm:@narumitw/pi-goal"

    # 侧线提问 (MIT, narumitw): /btw 开临时侧线程问问题, 不污染主对话, 主 agent 可继续运行
    # 用法: /btw <问题> 立即开问; /btw 打开管理器; 追问排队依次回答, Ctrl+Shift+F 搜索侧线程
    # Ctrl+R 把回答带回主编辑器 (最新问答 / 指定范围 / 完整线程, 可编辑不自动发送)
    # 默认沿用当前会话模型; 独立模型可配 ~/.pi/agent/pi-btw.json; 仅 TUI 模式
    "npm:@narumitw/pi-btw"

    # 官方 Context7 扩展 (MIT, Upstash): 给 agent 注入最新的库文档 (不依赖训练数据)
    # 工具: resolve-library-id 把包/产品名解析为库 ID, query-docs 拉取文档与代码示例; 模型遇到文档问题会自动调用
    # 手动查询: /c7-docs <库名> <问题> (如 /c7-docs next.js Cache Components)
    # 免配置即可用 (IP 限流); 提高配额: 到 context7.com/dashboard 申请免费 key, export CONTEXT7_API_KEY=ctx7sk_...
    "npm:@upstash/context7-pi"

    # --- --- --- 推荐使用 `pi install --local [ext-name]` 安装的扩展 --- --- ---

    # # 实时代码反馈 (MIT, apmantza): 编辑/写入文件后立刻给出语言感知的反馈
    # # - LSP 诊断与导航 (42 种语言服务器, 从 PATH / node_modules 自动发现, 缺装时交互式提示安装), 含影响级联诊断
    # # - 每次写入运行语言专属 linter / type-checker / 结构规则 (ast-grep, tree-sitter), 以及安全格式化/autofix
    # # - agent 工具: lens_diagnostics 查诊断, symbol_search 标识符搜索; /lens-map 生成 HTML 依赖图
    # # - 诊断可标记: 误报 (false-positive) / 源码抑制 / 推迟 / 待修
    # # 配置: 项目 .pi-lens.json, 全局 ~/.pi-lens/config.json; LSP 默认开启 (可用 --no-lsp 关闭)
    # # 注意: npm v12 下安装需批准依赖脚本 (npm approve-scripts); 首次安装会拉取较多工具链
    # # --local 理由: 功能绑定具体代码库, 且每个会话都会预热 LSP / 后台扫描 (非代码项目里纯开销);
    # # 在需要开发反馈的项目内 `pi install -l npm:pi-lens` 按需启用
    # "npm:pi-lens"

    # # 持久记忆 + 会话搜索 + 密钥扫描 (MIT, chandra447): 会话关闭即遗忘, 此扩展让记忆跨会话留存
    # # - 后台学习: 每 10 轮自动回顾, 保存事实/偏好/纠正/失败教训 (分类: failure/correction/insight/preference/convention/tool-quirk)
    # # - 会话搜索: SQLite FTS5 全文索引全部历史会话, agent 用 session_search 检索 (如 "上次 auth 怎么讨论的?")
    # # - 程序性技能: skill_manage 工具把"怎么做"存为 Pi 原生 SKILL.md (全局 ~/.pi/agent/pi-hermes-memory/skills/, 项目级 ~/.pi/agent/projects-memory/<项目>/skills/)
    # # - 密钥防护: API key / token / SSH key 等敏感内容会被拦截, 不写入记忆
    # # - 双层记忆: 全局 (MEMORY.md) + 项目级; 默认 policy-only 模式不注入提示词, 由 agent 按需调用 memory_search
    # # 常用命令: /memory-index-sessions (一次性索引历史会话) /memory-pin (常驻指令, 注入每个会话) /memory-interview (首会话画像) /learn-memory-tool
    # # 注意: 依赖 better-sqlite3 原生模块, 与 pi 运行时 Node ABI 不匹配时会自动 rebuild
    # # --local 理由: 每个会话都会做历史会话索引与后台学习 (耗启动时间与 token), 记忆场景绑定具体项目;
    # # 全局安装对日常问答过于冗余, 在需要长期记忆的项目内 `pi install -l npm:pi-hermes-memory` 按需启用
    # "npm:pi-hermes-memory"

    # # 仓库安全审计 (MIT, Vigolium): 多阶段源码安全审计 agent, 用专家子代理分阶段扫描
    # # deep 模式共 17 个阶段 (P1-P17, 五段流程): 侦察建模 → 静态分析 → 对抗验证 → PoC 与报告 → 清理
    # # 状态可恢复、并发受控; 产物写入目标仓库下 piolium/ 目录 (先看 final-audit-report.md)
    # # 常用命令: /piolium-lite <路径> (快速侦察+密钥扫描) /piolium-balanced (默认审计) /piolium-deep (全量深审, 可加 P1..P17 重跑指定阶段) /piolium-status (进度)
    # # ⚠️ 完整审计可能耗时数小时: 只对可信仓库运行, 或在沙箱目录中运行
    # # --local 理由: 安全审计绑定具体仓库的工作流, 全局安装只是多一次启动加载;
    # # 在需要审计的仓库内 `pi install -l npm:@vigolium/piolium` 按需启用
    # "npm:@vigolium/piolium"
  ];
}
