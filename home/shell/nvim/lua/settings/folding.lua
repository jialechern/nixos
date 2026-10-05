--- folding.lua
--- foldexpr 的唯一裁决点: 谁给这个 buffer 提供折叠(支持 foldingRange 的 LSP > treesitter)。
--- 之所以独立成模块: 原本三处各写一份 —— treesitter.lua 的 FileType、lsp.lua 的 LspAttach、
--- base.lua 的 loadview; 而 loadview 最后执行, 还会把 view 里陈旧的 foldexpr 一起恢复,
--- 于是"没有任何客户端"的 buffer 也可能指向 v:lua.vim.lsp.foldexpr()(该表达式此时返回 0 = 无折叠),
--- 折叠静默失效(见 docs/code-review-2026-10-01.md 的 BUG-02)。
--- detach 路径同理: 上游 State:on_detach 只清 state, 不改窗口里的选项字符串, 不重裁决的话
--- 折叠同样静默失效(docs/code-review-2026-10-02.md 的 BUG-06), 由本文件底部的 LspDetach 处理。
--- 本模块只写 foldmethod/foldexpr, 不碰 foldenable/foldlevel —— 折叠开关与折叠层级仍由
--- viewoptions='folds' 的 view 恢复, 从而保住"记住折叠"这个功能本身。

local M = {}

--- 该 buffer 是否已有支持 foldingRange 的客户端
---@param bufnr integer
---@param exclude_client_id? integer  -- LspDetach 时正在离开的客户端(它此刻还在 get_clients 里)
---@return boolean
local function lsp_can_fold(bufnr, exclude_client_id)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if client.id ~= exclude_client_id and client:supports_method('textDocument/foldingRange') then
            return true
        end
    end
    return false
end

--- 重新裁决本 buffer 的 foldexpr 归属; 两者都不用时保持不动(留给 view 或用户自己的设置;
--- 若此时 foldexpr 仍指向 lsp 表达式, 它会因无 state 返回 0, 与"无人提供折叠"的实际一致)
---@param bufnr integer
---@param exclude_client_id? integer
function M.refresh(bufnr, exclude_client_id)
    ---@type integer
    local win = vim.fn.bufwinid(bufnr)
    if win == -1 then
        -- FileType 阶段 buffer 可能还没进窗口, 当前 buffer 就先用当前窗口
        if bufnr ~= vim.api.nvim_get_current_buf() then
            return
        end
        win = 0
    end

    ---@type string?
    local owner
    if lsp_can_fold(bufnr, exclude_client_id) then
        owner = 'v:lua.vim.lsp.foldexpr()'
    elseif vim.b[bufnr].treesitter_fold then
        owner = 'v:lua.vim.treesitter.foldexpr()'
    else
        return
    end

    vim.api.nvim_set_option_value('foldmethod', 'expr', { win = win, scope = 'local' })
    vim.api.nvim_set_option_value('foldexpr', owner, { win = win, scope = 'local' })
end

--- LspDetach 在客户端真正离开**之前**触发(doc/lsp.txt: "Just before an LSP client detaches"),
--- 此时 get_clients 仍能看到它, 所以把 ev.data.client_id 排除后再裁决。
--- 若不重裁决: 窗口里的 foldexpr 字符串仍指向 v:lua.vim.lsp.foldexpr(), 而上游 detach 已清空
--- state(_folding_range.lua 的 State:on_detach), 该表达式此后对每行返回 '0' —— 折叠静默全失效。
vim.api.nvim_create_autocmd('LspDetach', {
    group = vim.api.nvim_create_augroup('folding-lsp-detach', { clear = true }),
    callback = function(ev)
        M.refresh(ev.buf, ev.data.client_id)
    end,
})

return M
