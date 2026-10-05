--- code_fold.lua
--- 代码折叠相关映射 (键位与描述见 lua/keys/code_fold.lua)

local map = require('utils.map').map
local keys = require('keys.code_fold')

--- zf/zd 只在 manual/marker 折叠方式下可用(见 :h zf); 本仓库主力文件类型都是
--- treesitter/LSP 的 expr 折叠, 原生映射在该方式下会静默抛 E350/E351(映射自带 silent)。
--- 这里显式判定并给出通知, manual/marker 时原样放行
---@param zcmd string
---@return fun(): string
local function guarded(zcmd)
    return function()
        local foldmethod = vim.api.nvim_get_option_value('foldmethod', { scope = 'local' })
        if foldmethod == 'manual' or foldmethod == 'marker' then
            return zcmd
        end
        vim.notify(
            ('foldmethod=%s 下无法手动折叠(仅 manual/marker 支持 %s)'):format(foldmethod, zcmd),
            vim.log.levels.WARN,
            { title = 'fold' }
        )
        return ''
    end
end

map(keys.close, 'zc')
map(keys.open, 'zo')
map(keys.delete, guarded('zd'), { expr = true })
map(keys.fold, guarded('zf'), { expr = true })
map(keys.expand_all, 'zR')
map(keys.close_all, 'zM')
