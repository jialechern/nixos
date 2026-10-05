--- conform.lua
--- 格式化统一入口(取代 settings/format.lua 的 formatprg 与 <C-\>f 原来的 vim.lsp.buf.format)。
--- 策略: 下表里的外部工具优先; 该文件类型没配工具、或工具不在 PATH 里时才回退 LSP(lsp_format = 'fallback')。
--- gq 也走这里, 但只在"该文件类型确实有可用外部工具"时才接管 formatexpr:
--- 不接管时文件类型仍按原样工作(typst/toml 等由 Neovim 自己的 LSP formatexpr 负责, markdown/纯文本走内置重排),
--- 否则 conform 的 formatexpr 会在没有格式化器可跑时返回 0, 让 gq 变成什么都不做。
--- 工具本身由 nix 提供(见 /etc/nixos/home/shell/nvim.nix); 新增语言: 下表加一行 + nix 侧确认工具已安装。

vim.cmd.packadd('conform.nvim')

local conform = require('conform')

--- filetype -> 格式化器名字(conform 内置表里的名字; 多个则按顺序执行)
--- 带点子类型(如 markdown.mdx)由 conform 自己按段回退, 不需要 utils/ft.lookup
---@type table<string, string[]>
local formatters_by_ft = {
    c = { 'clang-format' }, -- 读项目 .clang-format, 与 clangd 的 LSP 格式化同源
    cpp = { 'clang-format' },
    haskell = { 'ormolu' }, -- 与 lspconfig 给 hls 的 formattingProvider 一致
    javascript = { 'prettierd' },
    javascriptreact = { 'prettierd' },
    lua = { 'stylua' },
    nix = { 'nixfmt' },
    -- 只做格式化; 想在保存时顺带修 lint(ruff 官方 editors 文档的写法)就在前面加 'ruff_fix'/'ruff_organize_imports'
    python = { 'ruff_format' }, -- 取代旧的 black: 与 ruff LSP 的诊断同源
    rust = { 'rustfmt' },
    tex = { 'latexindent' },
    typescript = { 'prettierd' }, -- 旧 formatprg 只覆盖 javascript, 而 .ts 之前由 ts_ls 自带格式化器接管, 两者风格不同
    typescriptreact = { 'prettierd' },
}
-- 未列出的文件类型没有外部格式化器: typst(tinymist)、toml(taplo) 等由 LSP 兜底; markdown/纯文本不做格式化

conform.setup({
    formatters_by_ft = formatters_by_ft,

    -- 让 gq(formatexpr)与手动格式化沿用同一套回退策略(上游默认是 'never')
    default_format_opts = { lsp_format = 'fallback' },

    -- 保存时同步格式化(conform 自己挂 BufWritePre; 这里不允许 async, 要异步得改用 format_after_save)
    format_on_save = function(bufnr)
        -- :FormatDisable / :FormatDisable! 的开关
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
    end,

    formatters = {
        -- 沿用旧 formatprg 的两个参数: -m 允许调整换行, -c 把 indent.log 挪出项目目录。
        -- 用 append_args 而不是覆盖 args: 范围格式化(可视选中后 gq)走的是上游 range_args,
        -- 只覆盖 args 会让这两个参数在范围路径上静默丢失(indent.log 落回工作目录);
        -- append_args 会被同时追加到 args 与 range_args(conform/util.lua 的 add_formatter_args)
        latexindent = {
            append_args = { '-m', '-c', vim.fn.stdpath('cache') .. '/latexindent' },
        },
    },
})

-- gq: 仅当该文件类型有"真的能跑"的外部格式化器时才接管 formatexpr
local formatexpr_group = vim.api.nvim_create_augroup('conform_formatexpr', { clear = true })

---@param bufnr integer
local function take_over_formatexpr(bufnr)
    -- list_formatters_to_run 只返回真实可跑(工具在 PATH 里)的格式化器
    local formatters = conform.list_formatters_to_run(bufnr)
    if #formatters == 0 then
        return
    end
    vim.api.nvim_set_option_value('formatexpr', "v:lua.require'conform'.formatexpr()", {
        buf = bufnr,
        scope = 'local',
    })
end

vim.api.nvim_create_autocmd('FileType', {
    group = formatexpr_group,
    pattern = '*',
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        take_over_formatexpr(event.buf)
    end,
})

-- 手动格式化: 异步(不阻塞), 缓冲区在完成前被改动时 conform 会丢弃这次结果
-- (旧写法 vim.lsp.buf.format({async=true}) 会把过期结果写回缓冲区)
local map = require('utils.map').map
local keys = require('keys.lsp')
map(keys.format, function()
    conform.format({ async = true })
end)

-- 保存时自动格式化的开关(conform 文档里的配方: 全局或当前 buffer)
vim.api.nvim_create_user_command('FormatDisable', function(args)
    if args.bang then
        vim.b.disable_autoformat = true
    else
        vim.g.disable_autoformat = true
    end
end, { bang = true, desc = '关闭保存时自动格式化(带 ! 只关当前 buffer)' })

vim.api.nvim_create_user_command('FormatEnable', function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
end, { desc = '恢复保存时自动格式化' })
