--- split.lua
--- 分屏操作按键 (split_leader 命名空间)

local split_leader = '<C-s>'

---@class Keys.Windows.Split
---@field split_leader string  -- 命名空间前缀
---@field up KeySpec           -- 向上分屏
---@field down KeySpec         -- 向下分屏
---@field left KeySpec         -- 向左分屏
---@field right KeySpec        -- 向右分屏

---@type Keys.Windows.Split
local module = {
    split_leader = split_leader,

    up = { lhs = split_leader .. '<C-k>', desc = '向上分屏' },
    down = { lhs = split_leader .. '<C-j>', desc = '向下分屏' },
    left = { lhs = split_leader .. '<C-h>', desc = '向左分屏' },
    right = { lhs = split_leader .. '<C-l>', desc = '向右分屏' },
}

return module
