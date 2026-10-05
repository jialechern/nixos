--- close_window.lua
--- 特殊窗口(help / quickfix / 检查面板 / 测试输出等)的关闭键, 由 settings/autocmds.lua 按文件类型注册。

---@class Keys.CloseWindow
---@field close KeySpec -- 关闭当前窗口

---@type Keys.CloseWindow
local module = {
    close = { lhs = 'q', desc = '关闭当前窗口(help / quickfix / 检查面板等)' },
}

return module
