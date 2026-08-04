{
  # --- 输入 ---
  "tui.input.newLine" = [ "shift+enter" "ctrl+j" ]; # 插入换行
  "tui.input.submit" = "enter"; # 提交输入
  "tui.input.tab" = "tab"; # Tab / 自动补全

  # --- 选择列表 (模型选择器 /model、会话恢复等通用列表) ---
  "tui.select.up" = [ "up" "ctrl+p" ]; # 上移
  "tui.select.down" = [ "down" "ctrl+n" ]; # 下移
  "tui.select.confirm" = "enter"; # 确认选择
  "tui.select.cancel" = [ "escape" ]; # 取消选择

  # --- 应用操作 ---
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
