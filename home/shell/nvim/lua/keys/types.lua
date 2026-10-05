--- types.lua
--- 按键记录的类型定义 (仅供 lua-language-server 使用, 无运行时代码)

--- 一个按键: 键位 + 描述
--- 描述是快捷键唯一的文档来源(不再手写 help 文本), 因此必填且应写明"做什么"
---@class KeySpec
---@field lhs string              -- 键位, 与 vim.keymap.set 的 {lhs} 一致
---@field desc string             -- 描述
---@field modes? string|string[]  -- 生效模式, 缺省 'n'

return {}
