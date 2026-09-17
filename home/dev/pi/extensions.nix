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

    # 网页访问: 搜索 / 抓取 / GitHub 克隆 / PDF / 视频理解
    "npm:pi-web-access"

    # --- 已下沉为项目级扩展的包 (不在此全局加载, 见 home/dev/pi.nix) ---
    # 规划 / 目标 / 侧问 / 子代理 → localBaseExtensions   (pi-init)
    # 记忆 / LSP / 库文档          → localCodingExtensions (pi-coding)
  ];
}
