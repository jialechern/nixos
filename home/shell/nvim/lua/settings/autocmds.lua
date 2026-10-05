--- autocmds.lua
--- 存放与基础配置相关的自动命令(键位只写在 keys/ 里, 这里只注册行为)

local map = require('utils.map').map
local keys = require('keys.close_window')

---@class Settings.Autocmds
---@type Settings.Autocmds
local module = {}

---@param name string
---@return integer
local function augroup(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
end

-- 焦点/终端事件回到 nvim 时重新读入被外部修改的文件(:h :checktime)。
-- 不按当前 buffer 的 buftype 设防: 触发时用户可能停在 help/浮窗(nofile), 守卫会让所有
-- 文件 buffer 的外部改动都不被检查; 而 checktime 对 nofile buffer 本就无事可做
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
    group = augroup('checktime'),
    callback = function()
        vim.cmd('checktime')
    end,
})

-- 高亮复制结果(0.12 只需 vim.hl)
vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup('highlight_yank'),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- 如果窗口大小被调整，则调整分割大小
vim.api.nvim_create_autocmd({ 'VimResized' }, {
    group = augroup('resize_splits'),
    callback = function()
        ---@type integer
        local current_tab = vim.fn.tabpagenr()
        vim.cmd('tabdo wincmd =')
        vim.cmd('tabnext ' .. current_tab)
    end,
})

-- 打开缓冲区时转到最后编辑位置(视图文件只存折叠, 见 settings/base.lua 的 viewoptions)
vim.api.nvim_create_autocmd('BufReadPost', {
    group = augroup('last_loc'),
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        ---@type string[]
        local exclude = { 'gitcommit' }
        local buf = event.buf
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].did_jump_last_loc then
            return
        end
        vim.b[buf].did_jump_last_loc = true
        ---@type [integer, integer]
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- <q> 关闭这些一次性窗口
vim.api.nvim_create_autocmd('FileType', {
    group = augroup('close_with_q'),
    pattern = {
        'PlenaryTestPopup',
        'checkhealth',
        'help',
        'qf',
    },
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        map(keys.close, function()
            vim.cmd('close')
            pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
        end, { buffer = event.buf })
    end,
})

-- man 缓冲不进缓冲区列表(buflisted=false 只影响列表; 真正让 q 能关掉它的是内置 ftplugin/man.vim 的 <nowait> q)
vim.api.nvim_create_autocmd('FileType', {
    group = augroup('man_unlisted'),
    pattern = { 'man' },
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        vim.bo[event.buf].buflisted = false
    end,
})

-- json 不隐藏文本: conceallevel 默认就是 0, 这条是防御性的 —— conceallevel 是窗口局部选项, 会跨 buffer 残留,
-- 内置 rust/typst ftplugin 在开启 g:rust_conceal / g:typst_conceal 时会把它设成 2, 那时 json 也会跟着隐藏
vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = augroup('json_conceal'),
    pattern = { 'json', 'jsonc', 'json5' },
    callback = function()
        vim.opt_local.conceallevel = 0
    end,
})

-- 保存文件时自动创建目录，以防某些中间目录不存在
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
    group = augroup('auto_create_dir'),
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        if event.match:match('^%w%w+:[\\/][\\/]') then
            return
        end
        ---@type string
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
    end,
})

-- 自动切换输入法(仅 GNU/Linux, 需 `fcitx5-remote`), 当前关闭: InsertLeave 时若输入法处于中文态(2)则切回英文
-- vim.api.nvim_create_autocmd({ "InsertLeave" }, { pattern = { "*" }, callback = function()
--     local input_status = tonumber(vim.fn.system("fcitx5-remote")); if input_status == 2 then vim.fn.system("fcitx5-remote -c") end end })

return module
