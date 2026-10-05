-- settings.lua

-- 启用 neovim 原生 lsp (要最先加载, 否则会错过 LspAttach 事件)
require('settings.lsp')

-- 基础配置
require('settings.base')

-- 如果没有启用插件, 则设置背景透明度
if not vim.o.loadplugins then
    require('settings.transparency').apply_transparency()
end

-- 基本的自动命令
require('settings.autocmds')

-- 设置根据文件扩展名配置文件类型
require('settings.filetype')

-- 按文件类型应用定制, 每个关注点一个模块(取代原 after/ftplugin/*):
require('settings.indent') -- 缩进(宽度 + lisp 开关); 格式化(原 settings/format.lua)已改由 plugins/conform.lua 负责

-- 原生 treesitter(高亮/折叠): 按 FileType 启用, 与插件无关(--noplugin 下也生效)
require('settings.treesitter')
