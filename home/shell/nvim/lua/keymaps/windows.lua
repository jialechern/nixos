-- windows.lua
-- 放置分屏管理的快捷键配置 (键位与描述见 lua/keys/windows/)

-- 基本分屏功能
require('keymaps.windows.split')

-- 分屏时光标移动
require('keymaps.windows.cursor')

-- 分屏窗口大小控制
require('keymaps.windows.size')

-- 分屏状态控制
require('keymaps.windows.status')
