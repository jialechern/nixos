--- code_fold.lua
--- 代码折叠相关按键 (fold_leader 命名空间)

local fold_leader = '<C-f>'

--- 折叠按键在普通/可视模式下行为一致
---@param lhs string
---@param desc string
---@return KeySpec
local function nx(lhs, desc)
    return { lhs = lhs, desc = desc, modes = { 'n', 'x' } }
end

---@class Keys.CodeFold
---@field fold_leader string   -- 命名空间前缀
---@field close KeySpec        -- 关闭当前折叠
---@field open KeySpec         -- 打开当前折叠
---@field delete KeySpec       -- 删除当前折叠
---@field fold KeySpec         -- 创建折叠
---@field expand_all KeySpec   -- 展开全部
---@field close_all KeySpec    -- 关闭全部

---@type Keys.CodeFold
local module = {
    fold_leader = fold_leader,

    close = nx(fold_leader .. 'c', '关闭光标所在的折叠'),
    open = nx(fold_leader .. 'o', '打开光标所在的折叠'),
    delete = nx(fold_leader .. 'd', '删除光标所在的折叠(仅 manual/marker 折叠方式)'),
    fold = nx(fold_leader .. 'f', '创建折叠(仅 manual/marker 折叠方式)'),
    expand_all = nx(fold_leader .. 'e', '展开所有折叠'),
    close_all = nx(fold_leader .. 'a', '关闭所有折叠'),
}

return module
