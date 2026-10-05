--- split.lua
--- 分屏操作映射 (键位与描述见 lua/keys/windows/split.lua)

local map = require('utils.map').map
local keys = require('keys.windows.split')

-- 方位用窗口修饰符控制(aboveleft/belowright, 见 :h :aboveleft):
-- 旧写法先改全局的 splitbelow/splitright 再 split, 一次分屏会把会话默认写穿
map(keys.up, function()
    vim.cmd('aboveleft split')
end)

map(keys.down, function()
    vim.cmd('belowright split')
end)

map(keys.left, function()
    vim.cmd('aboveleft vsplit')
end)

map(keys.right, function()
    vim.cmd('belowright vsplit')
end)
