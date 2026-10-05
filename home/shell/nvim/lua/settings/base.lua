--- settings-base.lua

-- 字体编码
-- 自动识别文件编码优先级: ucs-bom 领头, 带 BOM 的 UTF-8/UTF-16(含 BE 与 astral 字符)由 BOM 判定,
-- 与内置一致; gbk/ucs-2le 兜住无 BOM 的场景(实测缺 ucs-bom 时 UTF-16BE 文件会被误判成乱码)。
-- gb2312 是 gbk 的子集, 排在后面实际不可达, 保留仅为语义声明
vim.opt.fileencodings = { 'ucs-bom', 'utf-8', 'gbk', 'gb2312', 'ucs-2le', 'latin1' }
-- 修复代码文件换行符/特殊字符乱码
vim.opt.fileformats = { 'unix', 'dos', 'mac' }

-- 禁用默认的启动界面
vim.opt.shortmess:append('I')

-- (这里原本写 `filetype plugin indent on`; Neovim 默认已启用 filetype 检测与 ftplugin/indent,
--  实测 -u NORC 打开 .rs/.py 时 ftplugin 与 indent 脚本都已加载, 故删除)

-- Hint: use `:h <option>` to figure out the meaning if needed
-- vim.opt.clipboard = 'unnamedplus'                       -- 使用系统剪贴板
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup' } -- popup: 补全菜单用浮窗(并显示候选预览)
vim.opt.mouse = 'a' -- 启用鼠标支持

-- Tab
vim.opt.tabstop = 4 -- tab 的宽度为 4 个空格
vim.opt.softtabstop = 4 -- 当按下 Tab 键时，插入 4 个空格
vim.opt.shiftwidth = 4 -- 自动缩进时使用 4 个空格
vim.opt.expandtab = true -- 将 Tab 键转换为空格

-- UI config
vim.opt.number = true -- 开启行号
vim.opt.relativenumber = true -- 开启相对行号
vim.opt.cursorline = true -- 显示光标所在行
vim.opt.cursorcolumn = true -- 高亮显示光标所在列
-- CursorLine/CursorColumn 的背景色不再在此设置: 插件路径由 catppuccin 决定,
-- 无插件路径走内置默认; 写在这里会在插件路径被覆盖成死配置
vim.o.winborder = 'rounded' -- 所有浮窗(诊断/悬停/补全文档)默认圆角边框

-- 光标闪烁: 发送闪烁序列, 动画节奏由终端 (kitty cursor_blink_interval) 统一控制
-- 与 fish 光标保持一致: normal/visual 方块、insert 竖线、replace 下划线
vim.opt.guicursor = {
    'n-v-c:block-blinkwait500-blinkon400-blinkoff250',
    'i-ci-ve:ver25-blinkwait500-blinkon400-blinkoff250',
    'r-cr:hor20-blinkwait500-blinkon400-blinkoff250',
    'o:hor50',
    'sm:block-blinkwait500-blinkon400-blinkoff250',
}

vim.opt.splitbelow = true -- 打开新水平分割时，新的窗口在下方
vim.opt.splitright = true -- 打开新垂直分割时，新的窗口在右侧
vim.opt.termguicolors = true -- 使用 24 bit rgb 颜色
vim.opt.showmode = false -- 是否显示模式（insert, normal 等）
vim.opt.laststatus = 3 -- 全局状态栏
vim.opt.showcmdloc = 'statusline' -- 半截命令(d / 2d / "a …)显示到状态栏的 %S 处
-- noice 会丢弃 showcmd 消息(它的 status.command 组件又有残留问题),
-- 交给原生 %S 最可靠; 对应的组件写在 plugins/lualine.lua

-- Searching
vim.opt.incsearch = true -- search as characters are entered
vim.opt.hlsearch = true -- 开启高亮搜索匹配结果
vim.opt.ignorecase = true -- 搜索时忽略大小写
vim.opt.smartcase = true -- 如果搜索包含大写字母，则不忽略大小写

-- 跳转行为: 追加 stack, 不改默认的 clean(跳转时清理同文件旧位置的标记)
vim.opt.jumpoptions:append('stack')

-- 光标上下保留 10 行滚动边距
vim.opt.scrolloff = 10

-- 视图只保存折叠: cursor/curdir 交给其它机制(见 autocmds.lua 的 last_loc)
vim.opt.viewoptions = 'folds'

-- 自动保存/恢复折叠信息
local fold_group = vim.api.nvim_create_augroup('remember_folds', { clear = true })
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = fold_group,
    callback = function()
        vim.cmd('silent! mkview')
    end,
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = fold_group,
    ---@param event vim.api.keyset.create_autocmd.callback_args
    callback = function(event)
        vim.cmd('silent! loadview')
        -- loadview 会把 view 里陈旧的 foldexpr/foldmethod 一并恢复, 所以恢复完要重新裁决一次
        -- (foldenable/foldlevel 不动, 折叠开关与层级仍以 view 为准)
        require('settings.folding').refresh(event.buf)
    end,
})

-- 设置自动保存
-- vim.opt.autowrite = true

-- 开启 DiffTool
vim.cmd('packadd nvim.difftool')
