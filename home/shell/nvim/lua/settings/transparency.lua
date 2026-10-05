--- transparency.lua
--- 只在无插件路径(--noplugin，没有 catppuccin)时给高亮组去背景;
--- 插件路径下 catppuccin 的 transparent_background / float.transparent 已覆盖这些组。
--- 注意: CursorLine/CursorColumn 不在此处理 —— 插件路径由 catppuccin 决定, 无插件路径走内置默认。

---@class Settings.Transparency
---@field apply_transparency fun()
local module = {}

--- 背景置 NONE: 必须带 update, 否则 nvim_set_hl 会整体替换组定义, 把 fg/style 一起抹掉
local function apply_transparency()
    ---@type string[]
    local transparent_groups = {
        'Normal',
        'StatusLine',
        'NormalFloat',
        'FloatBorder',
        'LspInlayHint',
        'DiagnosticVirtualTextError',
        'DiagnosticVirtualTextWarn',
        'DiagnosticVirtualTextInfo',
        'DiagnosticVirtualTextHint',
    }

    for _, group in ipairs(transparent_groups) do
        vim.api.nvim_set_hl(0, group, { bg = 'NONE', update = true })
    end
end

module.apply_transparency = apply_transparency

---@type Settings.Transparency
return module
