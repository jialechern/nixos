--- lsp.lua
--- LSP / 补全 / snippet 相关按键 (lsp_leader 命名空间)
--- 大部分由 settings/lsp.lua 在 LspAttach 时注册(buffer-local; 其中 type_hint/open_hint/close_hint 为条件注册),
--- format 由 plugins/conform.lua 全局注册(格式化已与 LSP 解耦), snippet_* 由 plugins/snippets.lua 注册

---@type string
local lsp_leader = '<C-' .. (vim.g.maplocalleader or '\\') .. '>'

--- snippet 按键: 原生片段会话只在插入模式(含 select)中活动
---@param lhs string
---@param desc string
---@return KeySpec
local function snippet_key(lhs, desc)
    return { lhs = lhs, desc = desc, modes = { 'i', 's' } }
end

---@class Keys.Lsp
---@field lsp_leader string          -- 命名空间前缀
---@field format KeySpec             -- 格式化(conform)
---@field goto_def KeySpec           -- 跳转定义
---@field goto_dec KeySpec           -- 跳转声明
---@field goto_ref KeySpec           -- 查找引用
---@field goto_impl KeySpec          -- 跳转实现
---@field show_doc KeySpec           -- 悬停文档
---@field rename KeySpec             -- 重命名
---@field code_action KeySpec        -- 代码操作
---@field goto_next_diag KeySpec     -- 下一个诊断
---@field goto_prev_diag KeySpec     -- 上一个诊断
---@field doc_in_new_window KeySpec  -- 浮窗显示完整诊断
---@field setloclist KeySpec         -- 诊断推送到 location list
---@field type_hint KeySpec          -- 参数提示开关
---@field doc KeySpec                -- 诊断显示开关
---@field open_hint KeySpec          -- 打开补全菜单
---@field close_hint KeySpec         -- 关闭补全菜单
---@field snippet_forward KeySpec    -- 展开/下一节点
---@field snippet_backward KeySpec   -- 上一节点
---@field snippet_clear KeySpec      -- 清除 snippet

---@type Keys.Lsp
local module = {
    lsp_leader = lsp_leader,

    format = { lhs = lsp_leader .. 'f', desc = '格式化当前缓冲区' },
    goto_def = { lhs = lsp_leader .. 'gd', desc = '跳转到定义' },
    goto_dec = { lhs = lsp_leader .. 'gD', desc = '跳转到声明' },
    goto_ref = { lhs = lsp_leader .. 'gr', desc = '查找引用' },
    goto_impl = { lhs = lsp_leader .. 'gi', desc = '跳转到实现' },
    show_doc = { lhs = lsp_leader .. 'd', desc = '浮窗显示符号文档' },
    rename = { lhs = lsp_leader .. 'r', desc = '重命名符号' },
    code_action = { lhs = lsp_leader .. 'ca', desc = '代码操作' },
    goto_next_diag = { lhs = lsp_leader .. 'n', desc = '跳转到下一个诊断' },
    goto_prev_diag = { lhs = lsp_leader .. 'p', desc = '跳转到上一个诊断' },
    doc_in_new_window = { lhs = lsp_leader .. 'w', desc = '浮窗显示完整诊断信息' },
    setloclist = { lhs = lsp_leader .. 'q', desc = '把当前缓冲区诊断推送到 location list' },
    type_hint = { lhs = lsp_leader .. 't', desc = '开/关参数提示(inlay hints)' },
    doc = { lhs = lsp_leader .. 'D', desc = '开/关诊断显示' },
    open_hint = { lhs = lsp_leader .. 'o', desc = '打开补全菜单', modes = 'i' },
    close_hint = { lhs = lsp_leader .. 'x', desc = '关闭补全菜单', modes = 'i' },

    snippet_forward = snippet_key('<C-.>', '展开片段或跳转到下一个节点'),
    snippet_backward = snippet_key('<C-,>', '跳转到上一个片段节点'),
    -- 不用 <C-c>: 插入模式下它是原生"退出插入但不触发 InsertLeave"的键, 不能被覆盖
    snippet_clear = snippet_key('<C-;>', '结束当前片段会话'),
}

return module
