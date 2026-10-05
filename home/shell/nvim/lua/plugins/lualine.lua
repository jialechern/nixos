vim.cmd.packadd('lualine.nvim')

local colors = require('settings.consts').colors

--- lualine 组件: 组件名/文本、返回文本的函数, 或 { 组件, 选项 } 表
---@alias LualineComponent string|fun(): string?|table

-- 状态栏主题: 每段的 a/b/c/z 给 fg/bg, gui = 'bold' 表示加粗
---@type table<string, table<string, table<string, string>>>
local theme = {
    normal = {
        a = { fg = colors.bg0, bg = colors.purple, gui = 'bold' }, -- 模式名: 用 Catppuccin 标志色 mauve
        b = { fg = colors.fg1, bg = colors.bg2 },
        c = { fg = colors.fg3, bg = 'NONE' }, -- 两侧填充: 透明底
        z = { fg = colors.bg0, bg = colors.purple }, -- 与 a 对称
    },
    insert = { a = { fg = colors.bg0, bg = colors.green, gui = 'bold' } },
    visual = { a = { fg = colors.bg0, bg = colors.orange, gui = 'bold' } },
    replace = { a = { fg = colors.bg0, bg = colors.red, gui = 'bold' } },
    command = { a = { fg = colors.bg0, bg = colors.frost4, gui = 'bold' } },
    terminal = { a = { fg = colors.bg0, bg = colors.frost1, gui = 'bold' } },
    inactive = { -- 非当前窗口整体变暗
        a = { fg = colors.fg3, bg = colors.bg1 },
        b = { fg = colors.fg3, bg = colors.bg1 },
        c = { fg = colors.fg3, bg = 'NONE' },
    },
}

-- 空组件: 不产出文本, 只用来在分段之间插入自定义底色的填充块
---@type table
-- 分隔块: 用 lualine 内部基类 component:extend() 造一个空组件(官方公开做法是 separator= + draw_empty,
-- 这里是沿用社区写法; 升级 lualine 时留意 component.lua 的 apply_highlights/apply_section_separators 是否还在)
local empty = require('lualine.component'):extend()

--- 覆盖 draw: 不画内容, 只应用分隔符与高亮
---@param default_highlight string lualine 传入的所在分段默认高亮组名
---@return string
function empty:draw(default_highlight)
    self.status = ''
    self.applied_separator = ''
    self:apply_highlights(default_highlight)
    self:apply_section_separators()
    return self.status
end

--- 给每个分段之间插入填充组件, 并把字符串 / 函数组件规范成 { 组件, 选项 } 表
---@param sections table<string, LualineComponent[]> 键为 lualine_a ~ lualine_z
---@return table<string, table[]> 处理后的 sections
local function process_sections(sections)
    for name, section in pairs(sections) do
        -- 段字母是第 9 个字符: x/y/z 属于状态栏右侧, 其余在左侧
        local left = name:sub(9, 10) < 'x'
        -- lualine_z 是最后一段, 它后面不再插填充块
        for pos = 1, name ~= 'lualine_z' and #section or #section - 1 do
            table.insert(section, pos * 2, { empty, color = { fg = colors.bg2, bg = colors.bg2 } })
        end
        for id, comp in ipairs(section) do
            if type(comp) ~= 'table' then
                comp = { comp }
                section[id] = comp
            end
            comp.separator = left and { right = '' } or { left = '' }
        end
    end
    return sections
end

--- 搜索计数: 只在 / 或 ? 触发过搜索且搜索寄存器非空时显示
---@return string
local function search_result()
    if vim.v.hlsearch == 0 then
        return ''
    end
    local last_search = vim.fn.getreg('/')
    if not last_search or last_search == '' then
        return ''
    end
    -- 判空用 next(searchcount) == nil: 上游文档说"上次搜索模式未设置时返回空字典"(:h searchcount()),
    -- lualine 内置组件也是这么判的; 只给 total/maxcount 做 or 兜底会在拼接 current 时抛错
    ---@type boolean, { current: integer, total: integer, maxcount: integer, incomplete: integer }
    local ok, searchcount = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
    if not ok or next(searchcount or {}) == nil or searchcount.incomplete == 1 then
        return ''
    end
    -- 字段级兜底: 非空字典仍可能缺某一项(官方组件是裸取值, 这里比它多了字段级兜底)
    ---@type integer
    local total = math.min(searchcount.total or 0, searchcount.maxcount or 999)
    -- 搜索模式原样进状态栏会被按 % 解析(%s/%b 之类被当成 item 吃掉);
    -- 上游 searchcount 组件只输出 [current/total]、不显示 pattern, 这里的 pattern 是超出官方的部分,
    -- 所以转义必须自己做(官方组件没有这一步, stl_escape 是它内部工具函数, 借来用)
    local pattern = require('lualine.utils.utils').stl_escape(last_search)
    return pattern .. '(' .. (searchcount.current or 0) .. '/' .. total .. ')'
end

--- 文件状态标记: '+' 已修改, '-' 只读或不可改
---@return string
local function modified()
    if vim.bo.modified then
        return '+'
    elseif vim.bo.modifiable == false or vim.bo.readonly == true then
        return '-'
    end
    return ''
end

-- noice 的状态组件: noice 会把 showcmd / showmode 消息从视图里 skip 掉, 只有它的 status 能读回来。
-- 这里只取 mode(宏录制提示): showcmd 会残留上一条内容(上游 issue #1076 / #1209),
-- 所以半截命令走 base.lua 的 showcmdloc = 'statusline' + 下面的 %S。必须延迟取值(本文件比 noice.lua 先加载)。
---@param name string noice status 名(当前只用 'mode')
---@return { [1]: fun(): string, cond: fun(): boolean }
local function noice_status(name)
    return {
        function()
            return require('noice').api.status[name].get() or ''
        end,
        cond = function()
            ---@type boolean, boolean
            local ok, has = pcall(function()
                return require('noice').api.status[name].has()
            end)
            return ok and has or false
        end,
    }
end

require('lualine').setup({
    options = {
        theme = theme,
    },
    sections = process_sections({
        lualine_a = { 'mode' },
        lualine_b = {
            'branch',
            'diff',
            {
                'diagnostics',
                -- 选项名是复数 sources; 取值见 lualine 的 components/diagnostics/sources.lua:
                -- nvim_diagnostic / nvim_workspace_diagnostic / nvim_lsp / coc / ale / vim_lsp
                sources = { 'nvim_diagnostic' },
                -- 一个组件里画 error / warn 两段, 省一次取诊断的开销
                sections = { 'error', 'warn' },
                diagnostics_color = {
                    error = { bg = colors.red, fg = colors.fg1 },
                    warn = { bg = colors.orange, fg = colors.fg1 },
                },
            },
            { 'filename', file_status = false, path = 1 },
            { modified, color = { bg = colors.red } },
            -- %w/%r/%q 在不适用时本来就渲染为空, 无需再写 cond
            '%w',
            '%r',
            '%q',
        },
        lualine_c = {},
        -- %S = 半截命令(由 base.lua 的 showcmdloc = 'statusline' 驱动), 空时自动跳过;
        -- 后面是宏录制提示, 见上面 noice_status 的说明
        lualine_x = { '%S', noice_status('mode') },
        lualine_y = { search_result, 'filetype' },
        -- 用 %v(屏幕列)而不是 %c(字节列): 中英文混排时 %c 的数会和肉眼位置对不上
        lualine_z = { '%l:%v', '%p%%/%L' },
    }),
    -- 不需要 inactive_sections: base.lua 里 laststatus = 3(全局状态栏),
    -- lualine 会自动按 globalstatus 工作, 非活动分段不会出场
})
