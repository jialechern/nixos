--- float_window.lua
--- 浮动窗口(消息历史 / 通知 / LSP 文档)相关按键 (float_window_leader 命名空间)

local float_window_leader = '<C-`>'

---@class Keys.Windows.FloatWindow
---@field float_window_leader string  -- 命名空间前缀
---@field last_message KeySpec        -- 最后一条消息
---@field history KeySpec             -- 消息历史
---@field dismiss KeySpec             -- 关闭所有通知
---@field scroll_doc_down KeySpec     -- LSP 文档向下滚动
---@field scroll_doc_up KeySpec       -- LSP 文档向上滚动
---@field redirect KeySpec            -- 命令行输出重定向到浮动窗口

---@type Keys.Windows.FloatWindow
local module = {
    float_window_leader = float_window_leader,

    last_message = { lhs = float_window_leader .. 'l', desc = '浮动窗口: 显示最后一条消息' },
    history = { lhs = float_window_leader .. 'h', desc = '浮动窗口: 显示消息历史' },
    dismiss = { lhs = float_window_leader .. 'd', desc = '浮动窗口: 关闭所有通知' },

    -- 不用官方样例的 <C-f>/<C-b>: 那两个键已经是 code_fold / buffers 命名空间的前缀,
    -- 直接占用会让前缀键互相等待超时
    scroll_doc_down = { lhs = float_window_leader .. 'j', desc = '浮动窗口: LSP 文档向下滚动' },
    scroll_doc_up = { lhs = float_window_leader .. 'k', desc = '浮动窗口: LSP 文档向上滚动' },

    -- 命令模式下按下: 保持命令行不动, 把这条命令的输出丢到浮动窗口里看
    redirect = { lhs = '<S-Enter>', modes = 'c', desc = '命令行: 把当前命令的输出重定向到浮动窗口' },
}

return module
