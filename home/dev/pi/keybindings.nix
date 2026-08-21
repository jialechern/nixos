{
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

  # --- 应用操作 ---
  # 会话选择器专用键: 原默认 ctrl+p (切换路径显示) / ctrl+n (仅命名会话过滤)
  # 与 tui.select.up/down 冲突, 换绑到 ctrl+shift+p / ctrl+shift+n
  # (两者当前均空闲; 如需完全禁用可改为 [])
  "app.session.togglePath" = "ctrl+]"; # 切换路径显示
  "app.session.toggleNamedFilter" = "ctrl+["; # 仅显示命名会话
  "app.interrupt" = "escape"; # 取消/中止
  "app.exit" = "ctrl+q"; # 退出 (输入为空时)
  "app.model.cycleForward" = "ctrl+\\"; # 循环到下一个模型
  "app.model.cycleBackward" = "ctrl+shift+\\"; # 循环到上一个模型
  "app.thinking.cycle" = "shift+tab"; # 循环思考等级
  "app.thinking.toggle" = "ctrl+f"; # 折叠/展开思考块
  # "app.message.copy" = "ctrl+x"; # 复制最后一条助手消息
  "app.message.followUp" = "ctrl+enter"; # 排队跟进消息
  "app.message.dequeue" = "ctrl+up"; # 撤回排队消息到输入框
}
