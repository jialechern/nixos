{
  # --- 扩展包资源 (npm/git 包) ---
  # 声明后 pi 首次启动时会自动通过 npm 安装到 ~/.pi/agent/npm/ 并加载
  # (需要网络; 若国内拉取失败, 请配置 npm 镜像或临时注释对应条目)
  packages = [
    # 权限控制 (MIT, gotgenes): 对工具 / bash / 路径 / MCP 实施 allow / ask / deny 三级策略
    # 策略文件: ~/.pi/agent/extensions/pi-permission-system/config.json
    "npm:@gotgenes/pi-permission-system"

    # 待办清单 (MIT, juicesharp): todo 工具 + /todos 命令 + 编辑器上方实时面板
    # 面板折叠键在 ~/.config/rpiv-todo/config.json 绑定为 ctrl+shift+f
    # (该键与内置 tui.altScreen.search 冲突, 后者已在 keybindings.nix 改绑 ctrl+shift+s)
    "npm:@juicesharp/rpiv-todo"

    # 结构化提问 (MIT, juicesharp): ask_user_question 工具, 模型拿不准时以选项式对话框向你确认
    "npm:@juicesharp/rpiv-ask-user-question"

    # 自主目标模式 (MIT, narumitw): 给 pi 一个会话级目标, 让它持续工作直到完成/暂停/等待/触达安全上限
    "npm:@narumitw/pi-goal"

    # Codex 风格只读规划模式 (MIT, narumitw): pi 核心未内置 plan mode, 此扩展补上
    "npm:@narumitw/pi-plan-mode"

    # TUI 界面扩展 (MIT, OldSuns): header / footer / 圆角编辑器 / 轮次遥测 / thinking peek
    # 配置见 extension-configs.nix → ~/.pi/agent/open-tui.json
    # 注意: 这是 UI 接管型扩展, 会重写编辑器边框与上下区域, 与上面的 rpiv-todo
    # 面板 (编辑器上方实时面板) 存在潜在重叠; 若显示异常可调整本数组的先后顺序
    # (列表在 builtins.toJSON 中保留顺序, 即加载顺序)
    "npm:pi-open-tui"

    # --- 已下沉为项目级扩展的包 (不在此全局加载, 见 home/dev/pi.nix) ---
    # 网页访问 / 子代理 / 记忆 → localBaseExtensions   (pi-init)
    # LSP / 库文档             → localCodingExtensions (pi-coding)
  ];
}
