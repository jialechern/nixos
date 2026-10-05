--- size.lua
--- 窗口尺寸调整按键 (步长见 settings/consts.lua 的 window_resize_step)

---@class Keys.Windows.Size
---@field left KeySpec   -- 当前窗口变窄
---@field right KeySpec  -- 当前窗口变宽
---@field up KeySpec     -- 当前窗口增高
---@field down KeySpec   -- 当前窗口变矮

---@type Keys.Windows.Size
local module = {
    -- desc 按"当前窗口尺寸变化"描述: resize 的分界线移动方向取决于窗口在布局中的位置,
    -- 写"分界线左移/上移"只在窗口位于分界线下/右方时成立
    left = { lhs = '<C-Left>', desc = '当前窗口变窄' },
    right = { lhs = '<C-Right>', desc = '当前窗口变宽' },
    up = { lhs = '<C-Up>', desc = '当前窗口增高' },
    down = { lhs = '<C-Down>', desc = '当前窗口变矮' },
}

return module
