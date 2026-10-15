--- blink-cmp.lua
--- 补全引擎: super-tab 风格(Tab 确认), cmdline 补全, 片段源接 mini.snippets。
--- 原生补全(settings/lsp.lua)保留作兜底: 本文件 pcall 守卫失败(插件未装)时直接返回,
--- vim.g.completion_plugin_active 不被设置, LspAttach 照旧启用 vim.lsp.completion, snippets.lua
--- 也继续起进程内 LSP 服务器把片段送进原生菜单 —— 两条原生路径完整回归, 无需改别处。

-- pcall 守卫只在 init 阶段有效: packadd 失败抛 E919 才会被接住, 运行期同一调用静默成功
-- (同 noice.lua 对 nvim-notify 的守卫; 本文件只被启动期的 plugins.lua require)
if not pcall(vim.cmd.packadd, 'blink.cmp') then
    return
end

local keys = require('keys.lsp')

require('blink.cmp').setup({
    -- 按键: super-tab 预设(Tab 确认/跳片段节点, <C-space> 手动开菜单), 叠加 keys.lsp
    -- 里的手动开/关菜单 —— show 打开菜单, cancel 关闭并撤销 auto_insert 的预插入,
    -- 语义与兜底路径里 <C-\>x 的 pumvisible→<C-e> 一致
    keymap = {
        preset = 'super-tab',
        [keys.open_hint.lhs] = { 'show', 'fallback' },
        [keys.close_hint.lhs] = { 'cancel', 'fallback' },
        -- super-tab 预设不含 <C-y>; 保留原生补全时代的确认键, 菜单没开时回落内置行为
        ['<C-y>'] = { 'select_and_accept', 'fallback' },
    },

    snippets = {
        preset = 'mini_snippets',
        -- mini_snippets 预设默认的 active/jump 走 MiniSnippets.session, 而 snippets.lua
        -- 自定义了 expand.insert(原生 vim.snippet 会话), session 不会建立 —— 必须整体
        -- 覆盖为原生实现, 才与 snippets.lua 的 <C-.>/<C-,>/<C-;> 共用同一套会话
        expand = function(snippet)
            vim.snippet.expand(snippet)
        end,
        active = function(filter)
            return vim.snippet.active(filter)
        end,
        jump = function(direction)
            vim.snippet.jump(direction)
        end,
    },

    sources = {
        -- 四件套(LazyVim/AstroNvim 惯例); buffer 默认只在 LSP 无结果时补位
        default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    completion = {
        -- super-tab 预设的官方建议: 片段会话中不再自动弹菜单, Tab 的"确认还是跳节点"才不歧义
        trigger = { show_in_snippet = false },
        menu = {
            -- 候选 label 按源语言用 treesitter 着色(LazyVim/AstroNvim 都开)
            draw = { treesitter = { 'lsp' } },
        },
        documentation = {
            -- 选中候选时浮窗显示文档(200ms 取自 LazyVim; 关掉改 auto_show=false)
            auto_show = true,
            auto_show_delay_ms = 200,
        },
    },

    -- nix 构建已把 Rust 模糊匹配库编译进插件(frizbee), 直接用本地实现:
    -- 不用 prefer_rust_with_warning 是避免仓库缺库时发警告, prebuilt_binaries 下载逻辑用不上
    fuzzy = { implementation = 'prefer_rust' },

    cmdline = {
        enabled = true,
        -- cmdline 预设(Tab 出菜单并插入首项, C-n/C-p 选择, C-y 确认, C-e 取消);
        -- 关掉左右键接管, 光标移动保持内置(LazyVim 惯例)
        keymap = {
            preset = 'cmdline',
            ['<Left>'] = false,
            ['<Right>'] = false,
        },
        completion = {
            -- 只在敲命令(:)时自动弹菜单, 搜索(/?)等仍走内置; Tab 手动出菜单不受限
            menu = {
                auto_show = function()
                    return vim.fn.getcmdtype() == ':'
                end,
            },
            -- noice 接管命令行时 blink 官方适配 ghost text(类似 shell 补全)
            ghost_text = { enabled = true },
        },
    },
})

-- 协调开关: 语义是"补全插件已接管, 原生路径让位", 故按能力而非插件名命名 ——
-- 将来换补全引擎时只需让新引擎的接入文件在 setup 成功后设置同名变量,
-- settings/lsp.lua 与 snippets.lua 两个消费方(以及文档口径)都不用动
vim.g.completion_plugin_active = true
