--- ft.lua
--- 按文件类型查配置表的公共入口: 带点子类型(scheme.guile)按段回退,
--- 与内置 ftplugin 装载器对带点类型的拆段行为一致(见 $VIMRUNTIME/ftplugin.vim
--- 的 "for name in split(s, '\.')": aaa.bbb 会依次加载 aaa 与 bbb)。

local M = {}

--- 从 tbl 里查 ft 的配置; 先查全名, 查不到再按 '.' 逐段回退。
--- 注意用 nil 判断而不是真值: 空串/0 也是合法配置值。
---@generic T
---@param tbl table<string, T>
---@param ft string
---@return T?
function M.lookup(tbl, ft)
    local value = tbl[ft]
    if value ~= nil then
        return value
    end
    for seg in string.gmatch(ft, '[^.]+') do
        value = tbl[seg]
        if value ~= nil then
            return value
        end
    end
    return nil
end

return M
