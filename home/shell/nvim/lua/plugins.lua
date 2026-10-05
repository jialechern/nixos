--- plugins.lua
--- 插件来源由 Nix 负责(home-manager programs.neovim.plugins 挂到 site/pack/hm/{start,opt}); 本文件只管加载时机与顺序。
--- packadd 认目录名(通常是插件仓库名), 与 nixpkgs 属性名不一定相同, 用 `ls ~/.local/share/nvim/site/pack/hm/opt` 核对。

-- 调用顺序即加载顺序, 不要随手挪动。
-- 每个 plugins/<name>.lua 被 require 时直接执行(先 packadd 再配置), 没有 setup() 壳
require('plugins.colorscheme') -- 主题最先, 否则高亮会被后加载的插件覆盖
require('plugins.nvim-lspconfig')
require('plugins.conform') -- 格式化(外部工具优先, LSP 兜底; 见该文件头部说明)
require('plugins.telescope')
require('plugins.snippets')
require('plugins.lualine')
require('plugins.noice')
