--- 交互输入的统一入口: 编号/文本各自的校验与取消语义只在这里定义一次。
--- 早期各映射点自行复制 '^%d+$' 守卫, 边界不全(放行了 "0", 文件名的空串没人管);
--- 新增需要用户输入的映射时优先用这里的函数, 不要再手写正则。

local M = {}

--- 询问一个整数: 非法输入或低于 min(默认 1)时返回 nil(空串即用户 <Esc> 取消, 同样 nil)。
--- min 用于表达各命令自己的编号空间: 多数命令编号从 1 起;
--- 例外如 :tabmove 的目标位置允许 0(移到最左), 调用处显式传 min=0
---@param prompt string
---@param min integer?
---@return integer?
function M.ask_number(prompt, min)
    local raw = vim.fn.input(prompt)
    local num = raw:match('^%d+$') and tonumber(raw) or nil
    if num and num >= (min or 1) then
        return num
    end
    return nil
end

--- 询问一段非空文本: 空串(含 <Esc> 取消)返回 nil
---@param prompt string
---@return string?
function M.ask_text(prompt)
    local raw = vim.fn.input(prompt)
    if raw ~= '' then
        return raw
    end
    return nil
end

return M
