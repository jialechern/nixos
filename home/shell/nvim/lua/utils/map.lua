--- map.lua
--- 按键映射的唯一入口: 键位与描述写在 lua/keys/<命名空间>.lua(见 KeySpec), desc 是唯一文档来源, 缺省即报错。
--- 用法: map(spec, rhs[, opts]) — rhs 为 string 或返回 string 的 expr 函数; opts 透传 vim.keymap.set(MapOpts)。
---@class MapOpts : vim.keymap.set.Opts
---@field modes? string|string[]  -- 生效模式, 覆盖 KeySpec.modes
---@field buffer? integer         -- 0 表示当前 buffer, 显式声明以便运行时类型库缺失时也能检查

--- 映射注册器(模块表): 注册入口与启动自检
---@class Map
---@field map fun(spec: KeySpec, rhs: string|(fun(): string?), opts?: MapOpts)
---@field check fun(): string[]

local M = {}

--- 已注册映射: registry[mode][lhs][作用域][注册来源] = true
---@type table<string, table<string, table<string, table<string, boolean>>>>
local registry = {}

---@param modes string|string[]
---@return string[]
local function to_mode_list(modes)
    if type(modes) == 'table' then
        return modes
    end
    return { modes }
end

--- 注册一个按键映射
---@param spec KeySpec      -- lua/keys/ 中的按键记录 { lhs, desc, modes? }
---@param rhs string|fun(): string?  -- 行为; 返回字符串时配合 expr 使用
---@param opts? MapOpts     -- 透传给 vim.keymap.set
local function map(spec, rhs, opts)
    if type(spec) ~= 'table' or type(spec.lhs) ~= 'string' then
        error('map: 第一个参数应为 keys 记录 { lhs, desc }, 实际收到 ' .. vim.inspect(spec), 2)
    end
    if type(spec.desc) ~= 'string' or spec.desc == '' then
        error('map: keys 记录缺少 desc (' .. spec.lhs .. ')', 2)
    end

    opts = opts or {}
    local modes = to_mode_list(opts.modes or spec.modes or 'n')
    local options = vim.tbl_extend('force', { silent = true }, opts)
    options.modes = nil -- 仅供本函数使用, 不能传给 vim.keymap.set
    -- desc 是唯一文档来源(写在 keys 表里), 即使 opts 传了也以 spec 为准, 防止注册处静默改写
    options.desc = spec.desc

    local info = debug.getinfo(2, 'Sl')
    local source = string.format('%s:%d', info and info.short_src or '?', info and info.currentline or 0)
    local scope = opts.buffer and ('buffer ' .. tostring(opts.buffer)) or '全局'

    -- registry 键用 Neovim 自己的归一化(replace_termcodes + keytrans, 不自研规则):
    -- `<C-A-Up>` 与 `<M-C-Up>` 归并到 `<M-C-Up>`, `<C-m>` 与 `<CR>` 同字节也归并到 `<CR>`。
    -- 不能用 maparg 回读代替: maparg 的 lhs 跟随查询串的记法(`<C-m>x` 查回 `<C-M>x`,
    -- `<CR>x` 查回 `<CR>x`), 对同字节异记法不合并(第二轮 RED-08 的残留, 见
    -- docs/code-review-2026-10-02-r3.md 的 BUG-07); 对非当前 buffer 注册也同样成立
    ---@type string
    local canonical = vim.fn.keytrans(vim.api.nvim_replace_termcodes(spec.lhs, true, true, true))

    for _, mode in ipairs(modes) do
        vim.keymap.set(mode, spec.lhs, rhs, options)
        registry[mode] = registry[mode] or {}
        registry[mode][canonical] = registry[mode][canonical] or {}
        registry[mode][canonical][scope] = registry[mode][canonical][scope] or {}
        registry[mode][canonical][scope][source] = true
    end
end

--- 启动自检: 报告同一作用域下被不同代码位置重复注册的键位
--- 同一处代码反复注册同一键位(如 ftplugin 对每个 buffer 各跑一次)是正常行为,
--- 只有"两个不同位置抢同一作用域的同一键位"才是真冲突
---@return string[]
function M.check()
    local problems = {}
    for mode, by_lhs in pairs(registry) do
        for lhs, by_scope in pairs(by_lhs) do
            -- 全局映射与 buffer-local 映射可以合法共存, 只在同作用域内比
            for scope, by_source in pairs(by_scope) do
                ---@type string[]
                local sources = vim.tbl_keys(by_source)
                if #sources > 1 then
                    table.sort(sources)
                    problems[#problems + 1] =
                        string.format('[%s] 键位重复 %s (%s): %s', mode, lhs, scope, table.concat(sources, ' 与 '))
                end
            end
        end
    end
    table.sort(problems)
    return problems
end

M.map = map

---@type Map
return M
