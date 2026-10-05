--- status.lua
--- 分屏布局调整映射 (键位与描述见 lua/keys/windows/status.lua)

local map = require('utils.map').map
local keys = require('keys.windows.status')

-- wincmd H/K 本身就是"移到最左/最上并占满整个高/宽"(:h CTRL-W_H), 前面再 wincmd t 不改变结果
map(keys.to_vertical, function()
    vim.cmd('wincmd H')
end)

map(keys.to_horizontal, function()
    vim.cmd('wincmd K')
end)

map(keys.up, function()
    vim.cmd('wincmd K')
end)

map(keys.down, function()
    vim.cmd('wincmd J')
end)

map(keys.left, function()
    vim.cmd('wincmd H')
end)

map(keys.right, function()
    vim.cmd('wincmd L')
end)
