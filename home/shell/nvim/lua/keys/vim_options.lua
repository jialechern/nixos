--- vim_options.lua
--- 交互设置 vim/neovim 内置选项的按键 (meta_leader 命名空间)

local meta_leader = '<C-m>'

---@class Keys.VimOptions
---@field meta_leader string      -- 命名空间前缀
---@field make_program KeySpec    -- makeprg
---@field grep_program KeySpec    -- grepprg
---@field grep_format KeySpec     -- grepformat
---@field shell_pipe KeySpec      -- shellpipe
---@field shell_redir KeySpec     -- shellredir

---@type Keys.VimOptions
local module = {
    meta_leader = meta_leader,

    make_program = { lhs = meta_leader .. 'm', desc = '交互设置 makeprg(编译命令)' },
    grep_program = { lhs = meta_leader .. 'g', desc = '交互设置 grepprg(搜索命令)' },
    grep_format = { lhs = meta_leader .. 'G', desc = '交互设置 grepformat(搜索结果格式)' },
    shell_pipe = { lhs = meta_leader .. 's', desc = '交互设置 shellpipe(命令输出重定向方式)' },
    shell_redir = { lhs = meta_leader .. 'S', desc = '交互设置 shellredir(命令输出重定向目标)' },
}

return module
