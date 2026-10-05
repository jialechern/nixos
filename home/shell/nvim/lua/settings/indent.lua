--- indent.lua
--- 按文件类型的缩进: 一张宽度表 + 单个 FileType autocmd。
--- 表里只列与全局默认(base.lua 的 4 空格)不同的项。
--- 说明: scheme 的 lisp 不在这里设 —— 内置 $VIMRUNTIME/ftplugin/scheme.vim 已有 `setl lisp`,
--- 这里再写一遍只是把"谁在写这个选项"变模糊(实测 -u NORC 打开 .scm 也是 lisp=true)。

local lookup = require('utils.ft').lookup

local M = {}

--- 文件类型 -> 缩进宽度
---@type table<string, integer>
M.widths = {
    haskell = 2, -- haskell 惯例
    nix = 2, -- nixpkgs 惯例
    scheme = 2, -- Scheme/Lisp 惯例
}

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_indent', { clear = true }),
    pattern = '*',
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        local ft = vim.bo[event.buf].filetype

        local width = lookup(M.widths, ft)
        if width then
            for _, name in ipairs({ 'tabstop', 'shiftwidth', 'softtabstop' }) do
                vim.api.nvim_set_option_value(name, width, { buf = event.buf, scope = 'local' })
            end
            vim.api.nvim_set_option_value('expandtab', true, { buf = event.buf, scope = 'local' })
        end
    end,
})

return M
