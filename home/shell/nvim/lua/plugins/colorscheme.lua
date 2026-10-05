-- 配置 neovim 的 Catppuccin 配色方案(Mocha 摩卡口味)
-- 只写与上游默认值不同的选项(catppuccin 2.0 defaults 见 lua/catppuccin/init.lua 的 default_options);
-- 与默认相同的键(background/dim_inactive/no_italic 等与 underlines)已清理, 避免假配置噪声

vim.cmd.packadd('catppuccin-nvim')

require('catppuccin').setup({
    flavour = 'mocha',

    transparent_background = true,
    -- 浮动窗口同样透明
    float = {
        transparent = true,
    },

    -- 同步调色板到终端颜色变量 g:terminal_color_0 ~ g:terminal_color_15
    term_colors = true,

    -- 语法高亮风格: 上游默认给 comments/conditionals 加斜体、@module/@tag 等硬编码斜体, 全部去掉
    -- (其余 styles/underlines/lsp_styles 的默认值本就符合预期, 不重复声明)
    styles = {
        comments = {},
        conditionals = {},
        miscs = {},
    },

    -- LSP 诊断相关: 虚拟文本不加斜体(上游默认 { "italic" })
    lsp_styles = {
        virtual_text = {
            errors = {},
            hints = {},
            warnings = {},
            information = {},
            ok = {},
        },
        -- 关掉 Inlay Hint 的色块, 保持透明(上游默认 background = true)
        inlay_hints = {
            background = false,
        },
    },

    integrations = {
        -- 命令行 / 消息 / LSP 文档浮窗配色(命令行浮窗边框色见 plugins/noice.lua)
        noice = true,
        -- 通知配色跟随后端: 现在不装 nvim-notify, 走 noice 内置 mini 视图(NoiceMini / NoiceFormatLevel*)
    },

    -- 不开 auto_integrations: 它只检测 vim.pack/lazy/packer 管理的插件(lib/detect_integrations.lua),
    -- 本仓库插件由 nix 挂 pack/hm, 检测恒为空。
    -- 注意 default_integrations(默认开)仍会默认启用 telescope/gitsigns/markdown 等常见集成;
    -- 只有 noice 这类不在默认表里的集成才必须像上面那样显式列出

    -- 编译缓存路径与默认一致(stdpath('cache')/catppuccin), 不再重复声明
})

vim.cmd.colorscheme('catppuccin-mocha')

-- 透明背景完全由上面的 transparent_background / float.transparent 负责;
-- settings/transparency.lua 只在无插件路径下被 settings.lua 调用。
