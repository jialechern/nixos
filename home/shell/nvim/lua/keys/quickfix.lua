--- quickfix.lua
--- quickfix / location list 相关按键 (fix_leader 命名空间)

local fix_leader = '<C-d>'

---@class Keys.Quickfix
---@field fix_leader string          -- 命名空间前缀
---@field open_fixwindow KeySpec      -- 打开窗口
---@field close_fixwindow KeySpec     -- 关闭窗口
---@field goto_item KeySpec           -- 跳到指定编号的条目
---@field next KeySpec                -- 下一条目
---@field previous KeySpec            -- 上一条目
---@field first KeySpec               -- 首条目
---@field last KeySpec                -- 末条目
---@field next_file KeySpec           -- 下一文件的第一个条目
---@field prev_file KeySpec           -- 上一文件的最后一个条目
---@field next_list KeySpec           -- 下一个 quickfix 列表
---@field next_list_by_index KeySpec  -- 第 n 个 quickfix 列表
---@field prev_list KeySpec           -- 上一个 quickfix 列表
---@field prev_list_by_index KeySpec  -- 回溯 n 个 quickfix 列表

---@type Keys.Quickfix
local module = {
    fix_leader = fix_leader,

    open_fixwindow = { lhs = fix_leader .. 'o', desc = '打开 quickfix 窗口' },
    close_fixwindow = { lhs = fix_leader .. 'c', desc = '关闭 quickfix 窗口' },
    goto_item = { lhs = fix_leader .. 'g', desc = '跳转到指定编号的条目' },
    next = { lhs = fix_leader .. 'j', desc = '跳转到下一条目' },
    previous = { lhs = fix_leader .. 'k', desc = '跳转到上一条目' },
    first = { lhs = fix_leader .. 'f', desc = '跳转到首条目' },
    last = { lhs = fix_leader .. 'l', desc = '跳转到末条目' },
    next_file = { lhs = fix_leader .. 'J', desc = '跳转到下一个文件的第一个条目' },
    prev_file = { lhs = fix_leader .. 'K', desc = '跳转到上一个文件的最后一个条目' },
    next_list = { lhs = fix_leader .. 'n', desc = '切换到下一个 quickfix 列表' },
    next_list_by_index = { lhs = fix_leader .. 'N', desc = '切换到第 n 个 quickfix 列表' },
    prev_list = { lhs = fix_leader .. 'p', desc = '回溯到上一个 quickfix 列表' },
    prev_list_by_index = { lhs = fix_leader .. 'P', desc = '回溯 n 个 quickfix 列表' },
}

return module
