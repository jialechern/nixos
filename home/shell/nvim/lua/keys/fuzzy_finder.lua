--- fuzzy_finder.lua
--- 模糊查找相关按键 (fuzzy_finder_leader 命名空间), 由 plugins/telescope.lua 注册

local fuzzy_finder_leader = '<C-q>'

---@class Keys.FuzzyFinder
---@field fuzzy_finder_leader string     -- 命名空间前缀
---@field files KeySpec                  -- 查找文件
---@field files_by_path KeySpec          -- 指定路径下查找文件
---@field files_in_git_repo KeySpec      -- git 仓库文件
---@field changes KeySpec                -- git 变更
---@field buffers KeySpec                -- 切换缓冲区
---@field rg KeySpec                     -- 全文搜索
---@field lines KeySpec                  -- 当前文件行搜索
---@field tags KeySpec                   -- 标签列表
---@field tags_in_current_buffer KeySpec -- 当前文件标签
---@field marks KeySpec                  -- 标记列表
---@field jumps KeySpec                  -- 跳转列表
---@field history KeySpec                -- 命令历史
---@field search KeySpec                 -- 搜索历史
---@field commands KeySpec               -- 查找命令
---@field keymaps KeySpec                -- 查找快捷键
---@field snippets KeySpec               -- 插入片段

---@type Keys.FuzzyFinder
local module = {
    fuzzy_finder_leader = fuzzy_finder_leader,

    files = { lhs = fuzzy_finder_leader .. 'f', desc = '查找文件' },
    files_by_path = { lhs = fuzzy_finder_leader .. 'F', desc = '在指定路径下查找文件' },
    files_in_git_repo = { lhs = fuzzy_finder_leader .. 'g', desc = '查找 git 仓库文件' },
    changes = { lhs = fuzzy_finder_leader .. 'C', desc = '查看 git 变更' },
    buffers = { lhs = fuzzy_finder_leader .. 'b', desc = '切换缓冲区' },
    rg = { lhs = fuzzy_finder_leader .. 'G', desc = '全文搜索(rg)' },
    lines = { lhs = fuzzy_finder_leader .. 'l', desc = '当前文件行搜索' },
    tags = { lhs = fuzzy_finder_leader .. 't', desc = '查找标签' },
    tags_in_current_buffer = { lhs = fuzzy_finder_leader .. 'T', desc = '当前文件标签' },
    marks = { lhs = fuzzy_finder_leader .. 'm', desc = '查找标记' },
    jumps = { lhs = fuzzy_finder_leader .. 'j', desc = '跳转列表' },
    history = { lhs = fuzzy_finder_leader .. 'H', desc = '命令历史' },
    search = { lhs = fuzzy_finder_leader .. 's', desc = '搜索历史' },
    commands = { lhs = fuzzy_finder_leader .. 'c', desc = '查找命令' },
    keymaps = { lhs = fuzzy_finder_leader .. 'k', desc = '查找快捷键' },
    snippets = { lhs = fuzzy_finder_leader .. 'S', desc = '选择并插入片段' },
}

return module
