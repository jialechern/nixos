--- tabs.lua
--- 标签页相关映射 (键位与描述见 lua/keys/tabs.lua)

local map = require('utils.map').map
local keys = require('keys.tabs')
local input = require('utils.input')

map(keys.edit, function()
    -- 空输入(含 <Esc> 取消)直接放弃, 否则 :tabedit 无参会开一个空白标签页
    local file = input.ask_text('请输入文件名: ')
    if not file then
        return
    end
    vim.cmd('tabedit ' .. vim.fn.fnameescape(file))
end)

map(keys.list, function()
    vim.cmd('tabs')
end)

map(keys.new, function()
    vim.cmd('tabnew')
end)

map(keys.close, function()
    vim.cmd('tabclose')
end)

map(keys.only, function()
    vim.cmd('tabonly')
end)

map(keys.window_to_tab, function()
    vim.cmd('wincmd T')
end)

map(keys.next, function()
    vim.cmd('tabnext')
end)

map(keys.previous, function()
    vim.cmd('tabprevious')
end)

map(keys.goto_tab, function()
    -- tabnext 的编号从 1 起, 0 会报 E475, 一并在 ask_number 里拒绝
    local num = input.ask_number('请输入标签页编号: ')
    if not num then
        return
    end
    vim.cmd('tabnext ' .. num)
end)

map(keys.move, function()
    -- 与 goto_tab 不同: tabmove 的 0 是合法目标(移到最左), 所以 min=0
    local num = input.ask_number('请输入目标位置: ', 0)
    if not num then
        return
    end
    vim.cmd('tabmove ' .. num)
end)

map(keys.first, function()
    vim.cmd('tabfirst')
end)

map(keys.last, function()
    vim.cmd('tablast')
end)
