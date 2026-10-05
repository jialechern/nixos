--- vim_options.lua
--- 交互设置 vim/neovim 内置选项 (键位与描述见 lua/keys/vim_options.lua)

local map = require('utils.map').map
local keys = require('keys.vim_options')

map(keys.make_program, function()
    ---@type string
    local makeprg = vim.fn.input('设定 makeprg(make-program) 为: ', '')
    vim.bo.makeprg = makeprg
end)

map(keys.grep_program, function()
    ---@type string
    local grepprg = vim.fn.input('设定 grepprg(grep-program) 为: ', '')
    vim.bo.grepprg = grepprg
end)

map(keys.grep_format, function()
    ---@type string
    local grepformat = vim.fn.input('设定 grepformat(grep-format) 为: ', '')
    -- 与配对的 grepprg 一致走 buffer-local(grepformat 是 global-local 选项), 换 buffer 不分裂
    vim.bo.grepformat = grepformat
end)

map(keys.shell_pipe, function()
    ---@type string
    local shellpipe = vim.fn.input('设定 shellpipe(shell-pipe) 为: ', '')
    vim.opt.shellpipe = shellpipe
end)

map(keys.shell_redir, function()
    ---@type string
    local shellredir = vim.fn.input('设定 shellredir(shell-redir) 为: ', '')
    vim.opt.shellredir = shellredir
end)

-- 不提供 formatprg 的交互设置: 'formatprg' 会被 'formatexpr' 压过(doc/options.txt), 而 conform 已给主要语言
-- 挂了 buffer-local formatexpr(plugins/conform.lua), 设了也不会生效 —— 详见 docs/code-review-2026-10-01.md 的 BUG-03。
-- 需要改格式化行为请走 conform 的 formatters_by_ft, 或对单独 buffer 用 :FormatDisable。
