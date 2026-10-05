--- buffers.lua
--- 缓冲区相关映射 (键位与描述见 lua/keys/buffers.lua)

local map = require('utils.map').map
local keys = require('keys.buffers')
local input = require('utils.input')

map(keys.previous, function()
    vim.cmd('bprevious')
end)

map(keys.next, function()
    vim.cmd('bnext')
end)

map(keys.first, function()
    vim.cmd('bfirst')
end)

map(keys.last, function()
    vim.cmd('blast')
end)

map(keys.list, function()
    vim.cmd('buffers')
end)

map(keys.goto_buffer, function()
    -- buffer 的编号从 1 起, 0 会报 E939(实测; 切 alternate 用的是下面的 alternate_file 键)
    local num = input.ask_number('请输入缓冲区编号: ')
    if not num then
        return
    end
    vim.cmd('buffer ' .. num)
end)

map(keys.alternate_file, function()
    vim.cmd('e #')
end)
