--- tabs.lua
--- 标签页相关按键 (tab_leader 命名空间)

local tab_leader = '<C-t>'

---@class Keys.Tabs
---@field tab_leader string      -- 命名空间前缀
---@field edit KeySpec           -- 新标签页打开文件
---@field list KeySpec           -- 列出标签页
---@field new KeySpec            -- 新建标签页
---@field close KeySpec          -- 关闭标签页
---@field only KeySpec           -- 仅保留当前标签页
---@field window_to_tab KeySpec  -- 窗口移到新标签页
---@field next KeySpec           -- 下一个标签页
---@field previous KeySpec       -- 上一个标签页
---@field goto_tab KeySpec       -- 跳到指定编号
---@field move KeySpec           -- 移动到指定位置
---@field first KeySpec          -- 第一个标签页
---@field last KeySpec           -- 最后一个标签页

---@type Keys.Tabs
local module = {
    tab_leader = tab_leader,

    edit = { lhs = tab_leader .. 'e', desc = '在新标签页打开文件' },
    list = { lhs = tab_leader .. 's', desc = '列出所有标签页' },
    new = { lhs = tab_leader .. 'c', desc = '新建标签页' },
    close = { lhs = tab_leader .. 'x', desc = '关闭当前标签页' },
    only = { lhs = tab_leader .. 'o', desc = '仅保留当前标签页' },
    window_to_tab = { lhs = tab_leader .. 't', desc = '将当前窗口移动到新标签页' },
    next = { lhs = tab_leader .. 'n', desc = '切换到下一个标签页' },
    previous = { lhs = tab_leader .. 'p', desc = '切换到上一个标签页' },
    goto_tab = { lhs = tab_leader .. 'g', desc = '跳转到指定编号的标签页' },
    move = { lhs = tab_leader .. 'm', desc = '将当前标签页移动到指定位置' },
    first = { lhs = tab_leader .. 'f', desc = '跳转到第一个标签页' },
    last = { lhs = tab_leader .. 'l', desc = '跳转到最后一个标签页' },
}

return module
