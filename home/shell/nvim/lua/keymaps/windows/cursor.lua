--- cursor.lua
--- 分屏间光标移动映射 (键位与描述见 lua/keys/windows/cursor.lua)

local map = require('utils.map').map
local keys = require('keys.windows.cursor')

map(keys.left, function()
    vim.cmd('wincmd h')
end)

map(keys.right, function()
    vim.cmd('wincmd l')
end)

map(keys.up, function()
    vim.cmd('wincmd k')
end)

map(keys.down, function()
    vim.cmd('wincmd j')
end)
