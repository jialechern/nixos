--- base.lua
--- 基础按键映射 (键位与描述见 lua/keys/base.lua)

local map = require('utils.map').map
local keys = require('keys.base')
local consts = require('settings.consts')

-- 领头键转译: 插入/命令行模式下输入对侧的领头键
map(keys.switch_to_local_leader, '<localleader>')
map(keys.switch_to_leader, '<leader>')

-- 实际行与屏幕行跳转对调
map(keys.screen_down, 'gj')
map(keys.screen_up, 'gk')
map(keys.line_down, 'j')
map(keys.line_up, 'k')

-- H/L/^/$ 不做映射: 直接用 Neovim 内置语义(屏幕首/末行 = H/L, 行首/行尾 = ^/$)

-- 快速上下移动(屏幕行, 与 j/k 对调口径一致), 行数取自 settings/consts.lua。
-- 注意 expr 映射返回的按键串不参与重映射(实测), 必须显式写 gj/gk 才是屏幕行
---@return string
map(keys.fast_down, function()
    return consts.fast_move_by_lines .. 'gj'
end, { expr = true })
---@return string
map(keys.fast_up, function()
    return consts.fast_move_by_lines .. 'gk'
end, { expr = true })

-- <Esc> 退出时顺带取消搜索高亮
---@return string
map(keys.escape, function()
    vim.cmd('noh')
    return '<esc>'
end, { expr = true })

-- 插入模式下在标点后打断撤销块
map(keys.undo_break_comma, ',<c-g>u')
map(keys.undo_break_dot, '.<c-g>u')
map(keys.undo_break_semicolon, ';<c-g>u')

-- 缩进后保持选中
map(keys.indent_left, '<gv')
map(keys.indent_right, '>gv')

-- 打开撤销树
map(keys.undotree, function()
    vim.cmd('packadd nvim.undotree')

    -- bufnr/winid 留空则由插件新建 buffer/窗口; command 是创建窗口的 Vim 命令(30vnew = 左侧 30 列),
    -- title 也可以是函数 fun(bufnr): string
    require('undotree').open({
        bufnr = nil,
        winid = nil,
        command = '30vnew',
        title = 'Undo Tree',
    })
end)
