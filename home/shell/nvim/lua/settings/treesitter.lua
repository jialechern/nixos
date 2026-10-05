--- treesitter.lua
--- Neovim 0.12 原生 treesitter: 高亮 + 折叠(缺 folds.scm 的语言自动退化为不折叠), 缩进仍走 $VIMRUNTIME/indent。
--- parser/queries 全由 nix 包提供(pack/hm/start/nvim-treesitter-{grammars,queries}), 与插件无关(--noplugin 下也生效)。

-- .tex 的文件类型叫 tex, 而 parser/queries 叫 latex
vim.treesitter.language.register('latex', 'tex')

---@type string[]
local filetypes = {
    'bash',
    'c',
    'cpp',
    'css',
    'go',
    'html',
    'java',
    'javascript',
    'json',
    'lua',
    'markdown',
    'nix',
    'python',
    'rust',
    'toml',
    'typescript',
    'vim',
    'vimdoc',
    'yaml',
    'zsh',
    'typst',
    'tex',
    'haskell',
    'scheme',
    'scheme.guile', -- 带点子类型必须显式列出, pattern 'scheme' 匹配不到它
}

local group = vim.api.nvim_create_augroup('UserTreesitter', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = filetypes,
    ---@param args vim.api.keyset.create_autocmd.callback_args
    callback = function(args)
        local ft = vim.bo[args.buf].filetype
        -- get_lang 会把 scheme.guile 这类带点子类型归到主类型(scheme)
        local lang = vim.treesitter.language.get_lang(ft) or ft
        -- nix 侧缺某个 grammar 时 start() 会 assert 报错, 先探一下再静默跳过
        if not vim.treesitter.language.add(lang) then
            return
        end

        vim.treesitter.start(args.buf, lang)

        -- foldenable 初值(全部打开)只在首次进入该 ft 时设定: 之后再触发 FileType(:setfiletype 等)
        -- 不覆盖用户手动开关; 日常的开关状态由 viewoptions='folds' 的 view 恢复(见 settings/base.lua)
        if vim.b[args.buf].treesitter_fold == nil then
            vim.opt_local.foldenable = false
        end
        -- 标记折叠由 treesitter 提供(settings/folding.lua 据此裁决)
        vim.b[args.buf].treesitter_fold = true
        require('settings.folding').refresh(args.buf)
    end,
})
