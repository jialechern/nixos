--- size.lua
--- 窗口尺寸调整映射 (键位与描述见 lua/keys/windows/size.lua)

local map = require('utils.map').map
local keys = require('keys.windows.size')
local step = require('settings.consts').window_resize_step

map(keys.left, function()
    vim.cmd('vertical resize -' .. step)
end)

map(keys.right, function()
    vim.cmd('vertical resize +' .. step)
end)

map(keys.up, function()
    vim.cmd('resize +' .. step)
end)

map(keys.down, function()
    vim.cmd('resize -' .. step)
end)
