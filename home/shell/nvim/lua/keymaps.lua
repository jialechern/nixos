-- keymaps.lua
-- 按键映射的装配入口: 各文件的顺序即注册顺序

-- 基础设置
require('keymaps.base')

-- vim 内置选项的交互设置
require('keymaps.vim_options')

-- 代码折叠快捷键
require('keymaps.code_fold')

-- 分屏相关的快捷键
require('keymaps.windows')

-- 缓冲区操作快捷键
require('keymaps.buffers')

-- 标签页操作快捷键
require('keymaps.tabs')

-- quickfix 相关快捷键
require('keymaps.quickfix')

-- 自检: 键位在同一作用域内重复注册会被报告出来 (描述缺失会在注册时直接报错)
---@type string[]
local problems = require('utils.map').check()
if #problems > 0 then
    vim.notify('快捷键自检发现问题:\n' .. table.concat(problems, '\n'), vim.log.levels.ERROR)
end
