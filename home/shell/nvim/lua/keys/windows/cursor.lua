--- cursor.lua
--- 分屏间光标移动按键

---@class Keys.Windows.Cursor
---@field left KeySpec   -- 光标左移
---@field right KeySpec  -- 光标右移
---@field up KeySpec     -- 光标上移
---@field down KeySpec   -- 光标下移

---@type Keys.Windows.Cursor
local module = {
    left = { lhs = '<C-h>', desc = '光标移动到左侧窗口' },
    right = { lhs = '<C-l>', desc = '光标移动到右侧窗口' },
    up = { lhs = '<C-k>', desc = '光标移动到上方窗口' },
    down = { lhs = '<C-j>', desc = '光标移动到下方窗口' },
}

return module
