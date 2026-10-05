--- telescope.lua
--- 模糊查找: telescope.nvim(取代原来的 fzf + fzf.vim)
--- 依赖(nix 提供) plenary.nvim / telescope-fzf-native.nvim; 键位见 keys/fuzzy_finder.lua

vim.cmd.packadd('telescope.nvim')
vim.cmd.packadd('plenary.nvim')

-- 原生排序器(可选): 装上才启用, 缺失时回退到 telescope 自带排序器
local has_fzf_native = pcall(vim.cmd.packadd, 'telescope-fzf-native.nvim')

local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup({
    defaults = {
        -- 布局: 结果在左、预览在右, 整体横纵居中(anchor 默认即居中, 写 'S' 会靠底)
        layout_config = {
            width = 0.9,
            height = 0.6,
            preview_width = 0.55,
        },
        sorting_strategy = 'ascending',
        -- 未安装 nvim-web-devicons, 不做图标着色(装上后可改成 true)
        color_devicons = false,
        -- 全局结果过滤: 带 filename 的 picker(含 live_grep)都会吃; Lua 模式按子串匹配(不加 ^ 才能挡住嵌套目录)
        file_ignore_patterns = { '%.git/', 'node_modules/' },
        -- live_grep / grep_string 走 ripgrep: --glob 剪掉任意层级的噪声目录
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden',
            '--glob',
            '!**/{.git,node_modules}/*',
        },
        mappings = {
            i = {
                -- 覆盖 telescope 默认的 <C-k>=preview_scrolling_right / <C-j>=nop, 换取 fzf 的上下选择手感
                ['<C-j>'] = actions.move_selection_next,
                ['<C-k>'] = actions.move_selection_previous,
            },
        },
    },
    pickers = {
        find_files = { hidden = true },
        buffers = { sort_mru = true },
    },
    -- fzf 扩展(fuzzy/override_*/case_mode)与 fzf-native 默认值逐键相同, 不重复声明;
    -- load_extension 即按默认启用
})

if has_fzf_native then
    telescope.load_extension('fzf')
end

-- --- --- --- 键位 --- --- ---
local map = require('utils.map').map
local keys = require('keys.fuzzy_finder')
local builtin = require('telescope.builtin')
local fn = vim.fn

map(keys.files, builtin.find_files)
map(keys.files_by_path, function()
    local path = fn.input('请输入搜寻的路径: ', fn.getcwd(), 'dir')
    if path ~= '' then
        builtin.find_files({ cwd = path })
    end
end)
map(keys.files_in_git_repo, builtin.git_files)
map(keys.changes, builtin.git_status)
map(keys.buffers, builtin.buffers)
map(keys.lines, builtin.current_buffer_fuzzy_find)
map(keys.tags, builtin.tags)
map(keys.tags_in_current_buffer, builtin.current_buffer_tags)
map(keys.marks, builtin.marks)
map(keys.jumps, builtin.jumplist)
map(keys.history, builtin.command_history)
map(keys.search, builtin.search_history)
map(keys.commands, builtin.commands)
map(keys.keymaps, function()
    -- 只列真实键位: 默认的 show_plug 会把 matchit/plenary 的 <Plug> 映射一起列出来
    builtin.keymaps({ show_plug = false })
end)
map(keys.snippets, function()
    -- 片段不经过 telescope: 走 mini.snippets 的 vim.ui.select 默认实现(编号列表);
    -- 这里的命令行与相关消息仍由 noice 渲染, 但列表本身不是 noice 提供的
    ---@type boolean, table
    local ok, snippets = pcall(require, 'mini.snippets')
    if ok and #snippets.expand({ insert = false }) > 0 then
        snippets.expand()
    else
        vim.notify('当前上下文没有可用片段', vim.log.levels.INFO, { title = 'snippet' })
    end
end)

-- ripgrep 缺失时全文搜索退化为文件查找(与原 fzf 配置一致)
if fn.executable('rg') == 1 then
    map(keys.rg, builtin.live_grep)
else
    map(keys.rg, builtin.find_files)
    vim.notify(
        '未检测到 ripgrep (rg), 全文搜索将退化为文件查找',
        vim.log.levels.INFO,
        { title = 'telescope' }
    )
end

-- --- --- --- 自定义命令(沿用原 fzf 配置里的三个) --- --- ---
---@param opts vim.api.keyset.create_user_command.command_args
vim.api.nvim_create_user_command('GrepWord', function(opts)
    local word = (opts.args ~= '' and opts.args) or fn.expand('<cword>')
    builtin.grep_string({ search = word })
end, { nargs = '?', desc = '用 ripgrep 搜索光标下的词(或指定词)' })

vim.api.nvim_create_user_command('RgVisual', function()
    -- 用未命名寄存器(最近一次 yank/删除): 可视选区不会自动进寄存器,
    -- 且本命令未声明 range, 从可视模式带 '<,'> 调用会报 E481
    local txt = fn.getreg('"')
    -- 多行只取第一行: rg 默认不跨行, 且换行会被 telescope 的 escape_chars 二次转义
    ---@type string
    local search = (txt:match('^[^\n]*') or '')
    if search ~= '' then
        builtin.grep_string({ search = search })
    else
        builtin.live_grep()
    end
end, { nargs = 0, desc = '搜索最近一次 yank/删除的文本' })

vim.api.nvim_create_user_command('FilesCwd', function()
    -- 优先从 git 仓库根目录开始查找(等价于原来 lcd 到仓库根再查文件)
    ---@type string? 不在 git 仓库内时取到 nil
    local git_root = fn.systemlist('git rev-parse --show-toplevel')[1]
    if git_root and git_root ~= '' then
        builtin.find_files({ cwd = git_root })
    else
        builtin.find_files()
    end
end, { nargs = 0, desc = '从 git 仓库根目录查找文件' })
