--- status.lua
--- 分屏布局调整按键

local split = require('keys.windows.split')

---@class Keys.Windows.Status
---@field to_vertical KeySpec    -- 改为纵向排列
---@field to_horizontal KeySpec  -- 改为横向排列
---@field up KeySpec             -- 窗口移至最上
---@field down KeySpec           -- 窗口移至最下
---@field left KeySpec           -- 窗口移至最左
---@field right KeySpec          -- 窗口移至最右

---@type Keys.Windows.Status
local module = {
    to_vertical = { lhs = split.split_leader .. 'V', desc = '改为纵向排列' },
    to_horizontal = { lhs = split.split_leader .. 'H', desc = '改为横向排列' },

    up = { lhs = '<C-A-Up>', desc = '将当前窗口移至最上' },
    down = { lhs = '<C-A-Down>', desc = '将当前窗口移至最下' },
    left = { lhs = '<C-A-Left>', desc = '将当前窗口移至最左' },
    right = { lhs = '<C-A-Right>', desc = '将当前窗口移至最右' },
    -- 备注: <C-A-*> 会被 Neovim 内部规范化为 <M-C-*>, :map 输出与表内记法不一致, 排查键位时注意
}

return module
