--- nvim-lspconfig.lua
--- LSP 服务器样板来自 nvim-lspconfig(上游提供 cmd / filetypes / root_markers); 这里只做 packadd + 统一启用。
--- 个性化覆盖写 after/lsp/<server>.lua(优先级更高); 上游配置名即服务器名, 写错时 vim.lsp.enable
--- 会**静默不启动**(无任何告警), 排查用 vim.lsp.is_enabled(name) 或对照上游 lsp/ 目录名单。

--- 启用的服务器(取代原先在 after/ftplugin/<ft>.lua 里逐个文件类型启用的写法)
---@type string[]
local servers = {
    'basedpyright',
    'clangd',
    'guile_ls',
    'hls',
    'lua_ls',
    'marksman',
    'nixd',
    'ruff',
    'rust_analyzer',
    'taplo',
    'texlab',
    'tinymist',
    'ts_ls',
}

-- 必须先把插件放到 runtimepath 上, vim.lsp.config/vim.lsp.enable 才能找到它的 lsp/*.lua
vim.cmd.packadd('nvim-lspconfig')
vim.lsp.enable(servers)
