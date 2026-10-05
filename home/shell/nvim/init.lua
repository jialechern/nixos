-- init.lua

-- 加载配置初始化时必要的符号
-- 领头键
vim.g.mapleader = '/'
-- 副领头键
vim.g.maplocalleader = '\\'

-- 一般设置
require('settings')

-- 引入插件(require 即按 plugins.lua 里的顺序加载; --noplugin 时整体跳过)
if vim.o.loadplugins then
    require('plugins')
end

-- 键盘映射
require('keymaps')
