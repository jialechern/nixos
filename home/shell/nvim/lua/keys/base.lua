--- base.lua
--- 基础按键: 领头键转译 / 屏幕行与实际行移动 / 快速移动 / 缩进 / 撤销断点 / 撤销树

local consts = require('settings.consts')

---@class Keys.Base
---@field switch_to_local_leader KeySpec  -- 插入副领头键
---@field switch_to_leader KeySpec        -- 插入领头键
---@field screen_down KeySpec             -- 按屏幕行下移
---@field screen_up KeySpec               -- 按屏幕行上移
---@field line_down KeySpec               -- 按实际行下移
---@field line_up KeySpec                 -- 按实际行上移
---@field fast_down KeySpec               -- 快速下移
---@field fast_up KeySpec                 -- 快速上移
---@field escape KeySpec                  -- 退出并取消搜索高亮
---@field undo_break_comma KeySpec        -- 逗号后打断撤销块
---@field undo_break_dot KeySpec          -- 句点后打断撤销块
---@field undo_break_semicolon KeySpec    -- 分号后打断撤销块
---@field indent_left KeySpec             -- 左缩进并保持选中
---@field indent_right KeySpec            -- 右缩进并保持选中
---@field undotree KeySpec                -- 打开撤销树

---@type Keys.Base
local module = {
    -- 领头键转译: 在插入/命令行模式下输入对侧的领头键
    -- 代价: 插入/命令行模式下单独输入 `/`、`\` 需等 timeoutlen(默认 1000ms)才上屏, 属有意取舍
    switch_to_local_leader = {
        lhs = '<leader><localleader>',
        desc = '插入副领头键 <LocalLeader>',
        modes = { 'i', 'c' },
    },
    switch_to_leader = { lhs = '<localleader><leader>', desc = '插入领头键 <Leader>', modes = { 'i', 'c' } },

    -- 实际行与屏幕行跳转对调: j/k 按屏幕行, gj/gk 按实际行
    screen_down = { lhs = 'j', desc = '向下移动(屏幕行, 与 gj 互换)' },
    screen_up = { lhs = 'k', desc = '向上移动(屏幕行, 与 gk 互换)' },
    line_down = { lhs = 'gj', desc = '向下移动(实际行, 与 j 互换)' },
    line_up = { lhs = 'gk', desc = '向上移动(实际行, 与 k 互换)' },

    -- H/L/^/$ 一律不覆盖, 保持 Neovim 内置语义: 屏幕首/末行 = H/L, 行首/行尾 = ^/$
    -- (曾经把这两组对调过, 已撤 —— 覆盖默认键会改掉视觉模式里 `$` 这类反射键的语义; 见 docs/code-review-2026-10-01.md 的 CMT-07)

    fast_down = {
        lhs = 'J',
        desc = string.format('向下快速移动 %d 个屏幕行', consts.fast_move_by_lines),
        modes = { 'n', 'x' },
    },
    fast_up = {
        lhs = 'K',
        desc = string.format('向上快速移动 %d 个屏幕行', consts.fast_move_by_lines),
        modes = { 'n', 'x' },
    },

    escape = { lhs = '<esc>', desc = '退出当前模式并取消搜索高亮', modes = { 'i', 'n', 's' } },

    -- 插入模式下在标点后打断撤销块
    undo_break_comma = { lhs = ',', desc = '插入逗号并打断撤销块', modes = 'i' },
    undo_break_dot = { lhs = '.', desc = '插入句点并打断撤销块', modes = 'i' },
    undo_break_semicolon = { lhs = ';', desc = '插入分号并打断撤销块', modes = 'i' },

    -- 缩进只在 visual 模式('x')生效, 不写 'v': 'v' 包含 select 模式, 而那里的用户预期是
    -- "打字即替换选区"(doc/visual.txt Select-mode-mapping: vmap 定义的映射在 select 下会
    -- 临时切 Visual 执行, 与该预期相反); 'x' 下 select 无映射, 按 < > 走内置的字面替换
    indent_left = { lhs = '<', desc = '左缩进并保持选中', modes = { 'x' } },
    indent_right = { lhs = '>', desc = '右缩进并保持选中', modes = { 'x' } },

    undotree = { lhs = '<C-u>', desc = '打开撤销树' },
}

return module
