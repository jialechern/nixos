--- noice.lua
--- noice.nvim: 命令行 / 消息 / LSP 文档(hover, signature)的 UI
--- 只写与上游默认值不同的配置; 核对默认值见 :help noice.nvim 与 lua/noice/config/init.lua 的 defaults()

vim.cmd.packadd('nui.nvim')
-- nvim-notify 是可选后端: noice 的 views.notify 自带 fallback = 'mini'(右下角一行), 装了
-- snacks.nvim 则优先用它。所以不硬 packadd, 缺失时静默降级(同 telescope.lua 对 fzf-native)。
local has_nvim_notify = pcall(vim.cmd.packadd, 'nvim-notify')
vim.cmd.packadd('noice.nvim')

local colors = require('settings.consts').colors

-- 通知窗口的"背后底色": 只在通知带淡入淡出(opacity)阶段时生效
if has_nvim_notify then
    require('notify').setup({
        background_colour = colors.bg1,
    })
end

require('noice').setup({
    cmdline = {
        -- 只换图标, 其余(pattern / lang / conceal / title)沿用默认值
        format = {
            cmdline = { icon = '$' },
            -- 上游 help 图标是 nerd-font 的“帮助”字形, 这里保留原来那个(问号书本)图标;
            -- 用字节转义写死(UTF-8 EF 9F 95), 避免工具链/编辑器改动字形
            help = { icon = '\239\159\149' },
        },
    },

    -- 补全菜单交给原生 vim.lsp.completion(见 settings/lsp.lua), 关掉 noice 的覆盖
    popupmenu = {
        enabled = false,
    },

    lsp = {
        -- hover / signature 浮窗里用 treesitter 的 markdown 解析做高亮:
        -- noice 的 view 层会读这个 lang 去调 vim.treesitter.start(view/init.lua)
        documentation = {
            opts = { lang = 'markdown' },
        },
    },

    -- 搜索计数已经在 lualine 的 search_result() 里显示; 上游默认还会往 virtualtext
    -- 视图送一份, 这里跳过以免重复(官方 doc ROUTES 一节的做法)
    routes = {
        {
            filter = { event = 'msg_show', kind = 'search_count' },
            opts = { skip = true },
        },
    },

    views = {
        -- 尺寸一律用百分比: nui 会按当前编辑器尺寸实时换算;
        -- 写成 math.floor(vim.o.columns * 0.8) 只会在启动时求值一次, 之后改窗口大小不再跟随
        cmdline_popup = {
            position = { row = '30%', col = '50%' },
            -- 百分比宽度会让上游默认的 min_width=60 失效(窄窗口下不再保底)
            size = { width = '80%' },
        },
        popup = {
            size = { width = '50%', height = 'auto' },
        },
        -- LSP hover / signature 浮窗边框: 与 0.12 的 winborder = 'rounded' 保持一致
        -- (上游 hover 视图默认 border.style = 'none')
        hover = {
            border = { style = 'rounded' },
        },
    },
})

-- noice 高亮只保留主动想要的差别, 其余交给 catppuccin 的 noice 集成; 透明背景由
-- colorscheme.lua(transparent_background + float.transparent)与 settings/transparency.lua 负责。
-- 注意 NoiceError / NoiceWarn 在 noice 里并不存在(消息级别颜色是 NoiceFormatLevel*), 别设置它们。
local cmdline_border_fg = colors.frost3

-- 主题切换会重建高亮组, 所以立即设一次 + 挂 ColorScheme 重设
local function set_noice_hls()
    vim.api.nvim_set_hl(0, 'NoiceCmdlinePopupBorder', { fg = cmdline_border_fg })
end

set_noice_hls()
vim.api.nvim_create_autocmd('ColorScheme', {
    -- 带 clear 的 augroup: 不然 :source $MYVIMRC 会重复追加回调
    group = vim.api.nvim_create_augroup('noice_highlights', { clear = true }),
    callback = set_noice_hls,
})

-- 键位与描述见 keys/windows/float_window.lua, 这里只写行为
local map = require('utils.map').map
local keys = require('keys.windows.float_window')

map(keys.last_message, function()
    require('noice').cmd('last')
end)
map(keys.history, function()
    require('noice').cmd('history')
end)
map(keys.dismiss, function()
    require('noice').cmd('dismiss')
end)

-- 把当前命令行的输出重定向到浮动窗口; 命令行保持打开, 便于改完再执行一遍
-- (官方 doc COMMAND REDIRECTION 一节的 recipe)
map(keys.redirect, function()
    require('noice').redirect(vim.fn.getcmdline())
end)

-- LSP hover / signature 浮窗里的翻页(官方 doc LSP HOVER DOC SCROLLING 一节的能力)
map(keys.scroll_doc_down, function()
    require('noice.lsp').scroll(4)
end)
map(keys.scroll_doc_up, function()
    require('noice.lsp').scroll(-4)
end)
