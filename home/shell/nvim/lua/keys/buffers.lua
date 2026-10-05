--- buffers.lua
--- 缓冲区相关按键 (buffer_leader 命名空间)

local buffer_leader = '<C-b>'

---@class Keys.Buffers
---@field buffer_leader string    -- 命名空间前缀
---@field previous KeySpec        -- 上一个缓冲区
---@field next KeySpec            -- 下一个缓冲区
---@field first KeySpec           -- 第一个缓冲区
---@field last KeySpec            -- 最后一个缓冲区
---@field list KeySpec            -- 列出所有缓冲区
---@field goto_buffer KeySpec     -- 跳到指定编号的缓冲区
---@field alternate_file KeySpec  -- 与上次编辑的文件互跳

---@type Keys.Buffers
local module = {
    buffer_leader = buffer_leader,

    previous = { lhs = buffer_leader .. 'p', desc = '切换到上一个缓冲区' },
    next = { lhs = buffer_leader .. 'n', desc = '切换到下一个缓冲区' },
    first = { lhs = buffer_leader .. 'f', desc = '切换到第一个缓冲区' },
    last = { lhs = buffer_leader .. 'l', desc = '切换到最后一个缓冲区' },
    list = { lhs = buffer_leader .. 's', desc = '列出所有缓冲区' },
    goto_buffer = { lhs = buffer_leader .. 'g', desc = '跳转到指定编号的缓冲区' },
    alternate_file = { lhs = buffer_leader .. '/', desc = '在当前文件与上次编辑的文件间跳转' },
}

return module
