--- consts.lua
--- 静态常量: 主题调色板 / 按键行为参数
--- 内容继续增长时, 拆分为 settings/consts/<主题>.lua

--- 主题调色板: Catppuccin Mocha 标准色
--- 供插件主题引用, 不要在别处硬编码色值; 消费方为 plugins/lualine.lua 与 plugins/noice.lua,
--- 改色需回归这两处(状态栏/通知配色)。
--- 只列实际用到的色值, 新增前先确认有引用方
---@class Consts.Colors
---@field bg0 string    -- 主编辑器背景 (base)
---@field bg1 string    -- 次要背景(状态栏、浮动窗口) (surface0)
---@field bg2 string    -- 选中区域背景 (surface1)
---@field frost1 string -- 浅青蓝 (teal)
---@field frost3 string -- 中蓝色 (sapphire)
---@field frost4 string -- 深蓝色 (blue)
---@field red string    -- 红色
---@field orange string -- 橙色 (peach)
---@field green string  -- 绿色
---@field purple string -- 紫色 (mauve)
---@field fg3 string    -- 次要文字 (subtext0)
---@field fg1 string    -- 高亮文字 (text)

---@class Consts
---@field colors Consts.Colors
---@field fast_move_by_lines integer   -- J/K 一次跨越的行数
---@field window_resize_step integer   -- 分屏尺寸调整步长

---@type Consts
local module = {
    colors = {
        -- Base: 背景深色系
        bg0 = '#1E1E2E',
        bg1 = '#313244',
        bg2 = '#45475A',

        -- 冷调青色/蓝色系
        frost1 = '#94E2D5',
        frost3 = '#74C7EC',
        frost4 = '#89B4FA',

        -- 强调色系
        red = '#F38BA8',
        orange = '#FAB387',
        green = '#A6E3A1',
        purple = '#CBA6F7',

        -- 文字浅色系
        fg3 = '#A6ADC8',
        fg1 = '#CDD6F4',
    },

    fast_move_by_lines = 5,
    window_resize_step = 5,
}

return module
