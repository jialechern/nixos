# AGENTS.md

本目录是 Neovim 配置的**真源**(Lua, 49 个文件 / 约 2.4k 行; 计数口径 = 在本目录下跑 `git ls-files --cached --others --exclude-standard '*.lua' | wc -l`)。它已并入 /etc/nixos 仓库, 由 `home/shell/nvim.nix` 以只读软链部署到 `~/.config/nvim`(见下)。无测试 / CI; 构建期只有一道 `luajit -bl` 语法检查, 语义验证靠"加载配置不报错"的几条命令(格式化由编辑器侧的 conform 负责, 见下)。

> 注: 下文引用的 `docs/code-review-*.md` 是迁移前旧独立仓库里的评审记录, 未并入本仓库, 引用只作编号出处。

## 硬性前提

- 需要 Neovim >= 0.12(本机 0.12.5)。注意别把这条当精确结论: 配置里用到的 `vim.lsp.config`/`vim.lsp.enable`、`winborder`、`vim.lsp.completion`(含 `autotrigger`)、`vim.treesitter.language.add` 在 0.11 就已可用, 真实最低版本没在本机验证过(没有 0.11 二进制)。
- 不要引入 lazy.nvim / packer / Mason 等插件管理器: **插件由 nix(`/etc/nixos/home/shell/nvim.nix` 的 `programs.neovim.plugins`)声明**, 懒加载靠 `packadd`(见下); LSP 二进制也由 home-manager 安装, 不在编辑器内装。
- 本目录不再有插件清单与 lockfile(`nvim-pack-lock.json` 已随 vim.pack 一起移除, 不要加回); `.pi/` 由仓库根 `.gitignore` 忽略。

## 部署链路: 改完不等于生效

- 真源是本仓库的 `home/shell/nvim/`; `home/shell/nvim.nix` 用 `pkgs.runCommand` 复制这份目录(构建期去掉 `AGENTS.md`、对全部 lua 跑 `luajit -bl` 语法检查)后, 经 `xdg.configFile."nvim"`(recursive) 以**只读软链**逐文件部署到 `~/.config/nvim`。所以 **改完必须 `sudo nixos-rebuild switch`** 才会作用到日常启动的 nvim; `~/.config/nvim` 里是 /nix/store 的软链, 不能就地编辑(唯一例外是下节的热调试文件)。
- 新增或改名的文件必须先在 /etc/nixos 里 `git add` 再 rebuild: flake 只复制 git 已索引的文件, 未跟踪的 lua 文件不会进部署树(且不会有任何告警)。
- 插件同源: 插件目录由 nix 声明并挂到 `~/.local/share/nvim/site/pack/hm/{start,opt}`, 新增/删除/改名插件必须改 `home/shell/nvim.nix` 的 `programs.neovim.plugins` 并 rebuild, 本目录的 `packadd` 才能找到它们。
- `programs.neovim.sideloadInitLua` 必须保持 `true`: nix 侧的 `initLua`(luajit `package.path` + 关闭 provider)靠它走 wrapper 的 `--cmd` 注入; 设成 `false` 时 HM 会把它写成 `~/.config/nvim/init.lua`, 与上面的部署同目标冲突。
- 例外: Neovim 自带的 dist 包(`$VIMRUNTIME/pack/dist/opt/` 下的 `nvim.undotree`/`nvim.difftool`)不归 nix 清单管, `packadd` 直接可用, 不要为它们改 nvim.nix。
- 不 rebuild 也能验证: 按下一节的方式用 `-u "$PWD/init.lua" --cmd "set rtp^=$PWD"` 从本目录启动, 加载的就是工作区代码(此时线上 `~/.config/nvim` 仍是旧配置)。这样跑 nvim 会写 `~/.local/share/nvim`(treesitter parser 等)与 `~/.local/state/nvim`, 属 state/cache 侧常规文件, 但别拿它当"临时沙箱"来试破坏性改动。

## 热调试通道: `~/.config/nvim/after/plugin/local-live.lua`

给"不想为一次试验 rebuild"留的口子(niri 的 `conf.d/local-live.kdl` 同款思路):

- 它由 `home/shell/nvim.nix` 的 tmpfiles 规则建成**可写实体文件**(不是 store 软链), 不在本仓库/flake 里 —— rebuild 不覆盖它, 写坏语法也不会让构建失败。
- 加载点是 nvim 原生机制: `runtimepath` 末尾的 `~/.config/nvim/after` 会在启动时自动 source 它的 `plugin/*.lua`, 所以它在**仓库配置与全部插件之后**执行, 可以覆盖它们; `--noplugin`/`-u NONE` 下不加载(上面那些自检命令因此不受它影响)。
- 生效方式: `:e ~/.config/nvim/after/plugin/local-live.lua` 边改边试, `:luafile %` 立即重载; `:restart`(保留会话)/`:restart!`(不保留) 全量重跑启动流程 —— 想在保存时自动重载就把下面这段放在文件开头(自重注册, 重载不会重复累积):

  ```lua
  vim.api.nvim_create_autocmd('BufWritePost', {
      group = vim.api.nvim_create_augroup('LocalLive', { clear = true }),
      pattern = 'local-live.lua',
      callback = function() vim.cmd.source(vim.fn.expand('<afile>')) end,
  })
  ```

- 其他注意事项: 写 autocmd 要用 `clear = true` 的 augroup, 否则每次重载会重复注册(选项/键位这类写法天然幂等); `.luarc.json` 与 `.stylua.toml` 就在上层目录, 所以编辑它有 `vim.*` 类型补全, 保存时 conform 会按仓库风格用 stylua 格式化; 在**别的** nvim 实例或外部编辑器里保存, 本实例不会自动重载(那是 `:restart` 的活)。
- 仓库里**不要**手写同名文件: 递归部署会用只读软链顶掉它(`home/shell/nvim.nix` 有求值期断言拦截)。

## 验证(全部在本目录下跑, 均不联网, 且**不需要 rebuild** —— 它们直接加载工作区代码; `-i NONE` 避免写 shada; #3 完整加载仍会追加 `~/.local/state/nvim/lsp.log`、写 catppuccin 编译缓存, 并按 `settings/base.lua` 的 mkview 给打开过的 buffer 各写一个 `~/.local/state/nvim/view/*`, 均属 state/cache 侧常规文件)

```bash
# 1) 全部 Lua 文件语法检查(最快, 不加载配置) → 期望输出 failures=0
nvim --headless -u NONE -i NONE -c 'lua local bad=0 for _,f in ipairs(vim.fn.glob("**/*.lua", false, true)) do local fn,e=loadfile(f) if not fn then bad=bad+1 io.write("FAIL "..f..": "..tostring(e).."\n") end end io.write("failures="..bad.."\n")' -c 'qa!'

# 2) 不加载插件地加载仓库(覆盖 settings/ keymaps/ 的 require 链, plugins 整体跳过, 退出码应为 0)
nvim --headless --noplugin -i NONE --cmd "set rtp^=$PWD" -u "$PWD/init.lua" -c 'qa!'

# 3) 完整加载(含 nix 提供的插件; packadd 名写错会在这一步以 require 失败暴露, 退出码应为 0)
nvim --headless -i NONE -u "$PWD/init.lua" --cmd "set rtp^=$PWD" -c 'qa!'

# 4) 快捷键自检 → 期望输出 keymap problems=0
nvim --headless -i NONE -u "$PWD/init.lua" --cmd "set rtp^=$PWD" -c 'lua local p=require("utils.map").check() io.write("keymap problems="..#p.."\n") for _,s in ipairs(p) do io.write(s.."\n") end' -c 'qa!'

# 5) 核对 nix 侧插件目录名(packadd 认的是目录名, 不是 nixpkgs 属性名)
ls -1 ~/.local/share/nvim/site/pack/hm/opt

# 6) 离线类型检查 → 期望 no problems found(不带 VIMRUNTIME 时运行时类型会解析不到)
export VIMRUNTIME=$(nvim --headless -u NONE -i NONE -c 'lua io.write(vim.fn.expand("$VIMRUNTIME"))' -c 'qa!')
lua-language-server --check=. --checklevel=Warning

# 7) 格式化风格自检 → 期望无输出(所有 lua 文件都符合本目录的 .stylua.toml; 删了配置会落回 Tab+双引号)
stylua --check $(git ls-files --cached --others --exclude-standard '*.lua')
```

`-u "$PWD/init.lua" --cmd "set rtp^=$PWD"` 是"用工作区代码启动"的通用姿势; 漏掉 `rtp` 前置会让 `require()` 全部落到线上配置。

## 结构与加载顺序

- `init.lua` → `require('settings')` → (`vim.o.loadplugins` 为真时)`require('plugins')` → `require('keymaps')`。nvim 还会在启动末尾自动 source `~/.config/nvim/after/plugin/local-live.lua`(见上节的热调试通道), 它不在这条 require 链里。
- `lua/settings.lua`: 顺序有意义, `settings.lsp` **必须最先**(否则错过 `LspAttach`); 无插件时(`loadplugins` 为假, 即 `--noplugin`; `-u NONE` 时配置整体不加载, 该分支不可达)才走 `settings.transparency`。
- 插件三步接入: 在 `/etc/nixos/home/shell/nvim.nix` 的 `programs.neovim.plugins` 里声明(懒加载写 `{ plugin = <包>; optional = true; }`, 进 `pack/hm/opt`; 直接写包名则进 `start`, 启动即加载) → 新建 `lua/plugins/<name>.lua`(**被 require 时直接执行**: 先 `vim.cmd.packadd('<目录名>')` 再配置; 不写 `setup()` 壳, 也没有 `local M`/`return M`) → 在 `lua/plugins.lua` 里按顺序加一行 `require('plugins.<name>')`。那里的顺序就是加载顺序(直接执行, 所以不要随手挪动)。
  - `packadd` 认**目录名**(通常是插件仓库名, 如 `lualine.nvim`、`mini.snippets`), 与 nixpkgs 属性名(`lualine-nvim`、`mini-snippets`)不一定相同; 名字对不上时的表现分两个阶段: init 阶段(启动期的所有调用点; 运行时调用点仅有 `keymaps/base.lua` 撤销树回调里的 dist 包 `packadd`, 恒存在不适用)抛 `E919`, 启动完成后同一调用才变成静默成功 —— `lua/plugins/noice.lua` 与 `lua/plugins/telescope.lua` 的 `pcall(vim.cmd.packadd, …)` 守卫正是靠 init 阶段会抛错才有效, 把这种调用挪到 autocmd/懒加载里就会永远返回 true。核对方法(nix 侧 opt 目录列表)写在 `lua/plugins.lua` 头部。
  - 插件的编译与运行期依赖(jsregexp、fzf 二进制、treesitter grammar 等)全部由 nix 负责, 仓库里不再有 build 钩子。
- LSP: 服务器样板由 **`nvim-lspconfig`** 提供(上游 `lsp/` 目录里的 `cmd`/`filetypes`/`root_markers`), 在 `lua/plugins/nvim-lspconfig.lua` 里 `packadd` + `vim.lsp.enable(servers)` 统一启用 —— 旧的 `lsp/<name>.lua` 目录与 `after/ftplugin/*` 里逐文件类型启用的写法(以及 `lua/utils/lsp_enable.lua`)已删除。要覆盖上游配置一律写 `after/lsp/<server>.lua`(优先级: 上游 `lsp/` → 你的 `after/lsp/` → `vim.lsp.config()`), **不要**再建 `lsp/` 与上游同名竞争。新增语言: 上游有配置 → 把服务器名加进 `lua/plugins/nvim-lspconfig.lua` 的 `servers` 表 + 在 `settings/filetype.lua` 里做扩展名映射; 上游没有 → 自己写 `after/lsp/<name>.lua`(文件名即服务器名)。
  - `guile_ls` 只能在带点子类型 `scheme.guile` 上启动, 所以 `settings/filetype.lua` 把 `.scm`/`.guile` 映射为 `scheme.guile`(通用的 `scheme` ftplugin 依然会加载, 实测有效)。
- 文件类型定制按关注点拆在 `lua/settings/indent.lua`(格式化已移出, 见下一条): 每个文件是一张业务命名的数据表(现在只有 `M.widths`) + 一个 FileType autocmd, `utils/ft.lua` 的 `lookup()` 统一处理带点子类型(`scheme.guile` 按段回退到 `scheme`); `after/ftplugin/*` 已整体删除, 不要重建。表里只列与全局默认不同的项(缩进 4 之类的不写); 新增语言在相关表里各加一行, 新增一类按文件类型的配置就新建一个这样的小模块并复用 `lookup()`。按文件类型设**窗口局部**选项(spell/wrap 这类)时必须走 `nvim_set_option_value(..., scope='local')` —— `vim.wo` 赋值会把全局默认一起写穿, 让某个文件类型的设置污染所有新窗口。
- 格式化由 **conform.nvim** 统一负责(`lua/plugins/conform.lua`): 外部工具优先、LSP 只兜底(`lsp_format='fallback'`), 同一张 `formatters_by_ft` 决定保存时格式化、`<C-\>f` 与 `gq`。旧的 `settings/format.lua`(formatprg)已删除, **不要再按文件类型配 formatprg**; `gq` 靠 conform 的 `formatexpr` 接管, 但只在"该文件类型有可用外部工具"时才接管 —— 不接管时 typst/toml 仍由 Neovim 自己的 LSP formatexpr 负责、markdown/纯文本仍走内置重排(否则 conform 的 formatexpr 会在没格式化器可跑时返回 0, 让 `gq` 什么都做不了)。保存时自动格式化默认开启, `:FormatDisable`(`!` 只关当前 buffer)/`:FormatEnable` 切换, `:ConformInfo` 看当前 buffer 会用哪个格式化器、工具是否就绪。
  - lua 的格式化器是 stylua, 本目录的 `.stylua.toml`(4 空格 + 单引号)是风格的唯一来源: **删掉它 stylua 会落回内置默认(Tab + 双引号), 每次保存把整文件重排**, 所以改风格只改这个文件, 然后跑验证第 7 条。
  - `formatters.<名字>.args` 只作用于**整文件**路径; 范围格式化(`gq` 选中几行)走上游的 `range_args`, 要给两条路径都加参数得用 `append_args`(conform 会把它追加到 args 与 range_args 两边, 见 `lua/plugins/conform.lua` 的 latexindent, 否则参数会静默只生效一半)。
- 非 LSP 的 lint(nvim-lint + shellcheck/markdownlint-cli2 + 迁移前的 `.markdownlint-cli2.jsonc`)已试配并**移除**: 需求由 LSP 诊断覆盖, 实际用不上, 不要顺手加回。
- 按文件类型的 makeprg/编译运行(`<C-e>` 运行键, 含 typst 预览/nix build 自定义 runner)与 spell/wrap/textwidth 覆盖已整个删除(`settings/build.lua`、`keys/run.lua`、`settings/text.lua` 不复存在, `settings/autocmds.lua` 的 wrap_spell autocmd 已删): `:make` 回到全局 makeprg=make, markdown 不再查拼写, tex 恢复软换行, formatoptions 保持内置默认。需要时从会话记录或按需重写, 别顺手重建。
- 对齐插件已删除(`lua/plugins/vim-easy-align.lua` 与 `lua/keys/align.lua` 不复存在, `ga` 回归内置的字符编码查询): 上游自 2024-07 起停更, 交互修饰键又不可发现。再需要对齐时优先交给格式化器/语言工具(c/cpp 已在 `lua/plugins/conform.lua` 挂了 `clang-format`, 它读项目 `.clang-format`, 在项目里开 `AlignConsecutiveAssignments` 即可), 或重新评估 mini.align; 不要按旧教程把 vim-easy-align 加回来。
- 类型解析与 LSP 配置无关: `lua_ls` 认识 `vim.*` 靠本目录的 `.luarc.json` 的 `workspace.library`(`${env:VIMRUNTIME}/lua`); 该变量由 nvim 自己设置, 命令行离线复检时才需要 `export VIMRUNTIME`。
- 键位与描述单一来源: 每个 `lua/keys/<命名空间>.lua` 导出 Hash Map(字段名 snake_case; 有前缀的命名空间其领头键以 `<名字>_leader` 字段放在同一张表, 无前缀的如 `close_window`、`windows.cursor|size` 直接写完整 lhs, 不设 leader 字段), 每个按键是 `KeySpec = { lhs, desc, modes? }`(`modes` 缺省 `'n'`), 类型定义在 `lua/keys/types.lua`。使用处 `local keys = require('keys.<命名空间>')`, 用 `map(keys.<字段>, rhs[, opts])` 注册(变量名统一用 `keys`, 不要用单字母缩写)。
  - `lua/keymaps/*`(通用/命名空间)与 `settings/` 下按文件类型的模块(`indent`)、插件内部一律只写行为, **不要在映射处硬编码 lhs 或写 desc**; desc 只写在 keys 表里(它是快捷键唯一的文档来源, 不再手写 help 映射)。
  - `keys/` 内部相互引用时不要再用 `keys` 这个名字(避免与"本文件的表"混淆), 用该命名空间的短名, 如 `local split = require('keys.windows.split')`。
  - `require('utils.map').map(spec, rhs, opts)` 是唯一入口: 支持 `{ modes = {...} }` 覆盖模式、透传 `vim.keymap.set` 选项(如 `buffer`); 缺 `desc`/`lhs` 会在注册时报错。已删除 `map_by_modes`(`vim.keymap.set` 原生支持模式列表)与 `noremap`(0.12 已不支持, 非递归本就是默认)。
  - 启动自检 `require('utils.map').check()` 在 `lua/keymaps.lua` 末尾调用: 报告同一作用域下被**不同代码位置**抢注的键位(同一处代码重复注册、以及全局与 buffer-local 并存都不算冲突); 新增/改动键位后跑验证第 4 条。人工浏览全部已注册键位用 fuzzy finder 的 `<C-q>k`(telescope `builtin.keymaps`, 传 `show_plug = false` 滤掉 matchit/plenary 的 `<Plug>` 噪声)。
  - 有的命名空间只在特定上下文注册: LSP 在 `settings/lsp.lua` 的 `LspAttach`、关闭特殊窗口的 `q` 在 `settings/autocmds.lua`、fzf/补全/浮动窗口在对应插件里。按文件类型注册的映射**必须带 buffer**(如 `{ buffer = buf }`; 否则会覆盖全局键位, 切回旧 buffer 时会跑错语言)。
- 非按键的静态配置(调色板、行为参数)集中在 `lua/settings/consts.lua`, 例如 `colors`、`fast_move_by_lines`、`window_resize_step`; 内容变大再拆 `lua/settings/consts/`。
- leader 约定: `<Leader>` = `/`, `<LocalLeader>` = `\`, LSP 前缀 `<C-\>`(`keys.lsp.lsp_leader`, 它由 `<LocalLeader>` 拼接派生 —— 改 `\` 会连带改 `<C-\>`), fuzzy finder `<C-q>`(`keys.fuzzy_finder.fuzzy_finder_leader`)。`vim.g.mapleader` / `vim.g.maplocalleader` 在 `init.lua` 定义; keys 表里取前缀用 `vim.g.maplocalleader`, 不要读全局变量(否则 lua_ls 报 `undefined-field`)。默认**不覆盖 Neovim 内置键**(曾经把 H/L 与 ^/$ 对调, 已撤销, 见 `docs/code-review-2026-10-01.md` 的 CMT-07);例外只保留普通模式的 `<C-u>`(改为打开撤销树, 内置的"上滚半屏"不再可用)与 `J`/`K`(改为按 5 个屏幕行快速移动, 内置 J 行连接 / K keywordprg 不再可用; 屏幕行口径与 j/k↔gj/gk 对调一致), 新增这类例外要在这里记一笔并说明理由。与内置键的另外两类重叠属**既定取舍**: ① 9 个命名空间前缀(`<C-b>/<C-d>/<C-f>/<C-m>/<C-q>/<C-s>/<C-t>/<C-\>/``<C-`>```)以内置键字节开头(`<C-m>`≡`<CR>`, `:h index.txt`), 这些内置键(Enter/<C-b>/<C-d>/<C-f>/<C-t> 翻页与 tag 回退)会先等 `timeoutlen`(默认 1000ms, `:h map-ambiguous`)再回落内置行为; ② `<C-h>/<C-j>/<C-l>` 直接覆盖内置 h/j/l(redraw)、`<C-k>`(内置未用)用作窗口光标移动。
- 补全与片段: blink.cmp / LuaSnip 已删除, 改用 Neovim 原生实现 —— 补全在 `lua/settings/lsp.lua` 的 `LspAttach` 里用 `vim.lsp.completion.enable()` 启用(`<C-y>` 确认、`<C-e>` 取消), 片段用 `lua/plugins/snippets.lua` 的 `mini.snippets` + `friendly-snippets`, 引擎为 `vim.snippet`(展开/跳转/停止都用 `vim.snippet.*` 原生会话, 不再用 mini.snippets 的 session API); 相应的 `keys.lsp` 里的 `open_hint`/`close_hint`/`snippet_*` 由这两处注册。
- snippets: 自研片段已全部弃用(`snippets/` 目录不存在, 不要重建), 只用社区集合; 片段会经 mini.snippets 起的进程内 LSP 服务器进入原生补全菜单。
- 类型标注: 本目录的 `.luarc.json`(LuaJIT + `undefined-field` 提到 Warning + `different-requires` 降为 Information + 忽略 `.pi`)的 `workspace.library` 指向 `${env:VIMRUNTIME}/lua`, 才能解析 `vim.keymap.set.Opts`、`vim.api.keyset.create_autocmd.callback_args` 等运行时类型; 离线跑 `lua-language-server --check=. --checklevel=Warning` 前要 `export VIMRUNTIME`。
  - `different-requires` 降级的原因: `require('plugins.noice')` 与 `require('noice')` 都会被 lua-language-server 解析到 `lua/plugins/noice.lua`(插件源码不在 workspace), 属误报。
- 主题: catppuccin mocha + 透明背景。高亮覆盖分两条互不重叠的路径: `lua/plugins/colorscheme.lua`(catppuccin 选项, 插件路径)与 `lua/settings/transparency.lua`(`--noplugin` 时由 settings.lua 调用); 改透明相关先确认走哪条。
- treesitter: **纯原生**(Neovim 0.12), 不依赖 nvim-treesitter 插件 —— `lua/settings/treesitter.lua`(settings.lua 里无条件加载, --noplugin 下也生效)只做 `vim.treesitter.start()` 高亮 + `foldenable` 初值与 `treesitter_fold` 标记(折叠归属见下一条 `settings/folding.lua`); parser 与 queries 全由 nix 提供(两个 start 包: `pack/hm/start/nvim-treesitter-grammars` 提供 320 个 parser, `pack/hm/start/nvim-treesitter-queries` 提供 300+ 语言的 queries, 取自上游 nvim-treesitter 的 `runtime/queries`), 声明在 `/etc/nixos/home/shell/nvim.nix`; `~/.local/share/nvim/site/{parser,parser-info,queries}` 是旧 ts.install 残留, 已删除; **site/pack/hm 不能删**。0.12 原生没有 treesitter 缩进, 缩进交给 `$VIMRUNTIME/indent/<ft>.vim`。新增语言: nix grammar 列表 + 该文件的 `filetypes` 各加一项(缺 parser 时静默跳过不报错); ft 名与 parser/queries 名不同时先 `vim.treesitter.language.register('<parser>', '<ft>')`(现存唯一实例: tex→latex, 见 `lua/settings/treesitter.lua` 头部)。0.12 还内置了 treesitter 增量选择: Visual 模式 `an`/`in`/`[n`/`]n`/`[N`/`]N`。
- 折叠(`foldexpr`/`foldmethod`)归属由 `lua/settings/folding.lua` 统一裁决, 优先级 = 支持 `textDocument/foldingRange` 的 LSP > treesitter; 它在四处被调用: `settings/treesitter.lua` 的 FileType、`settings/lsp.lua` 的 LspAttach、`settings/base.lua` 的 `BufWinEnter`、以及 `folding.lua` 自己注册的 `LspDetach`(注意它触发于客户端真正离开**之前**, 要把 `ev.data.client_id` 排除后再裁决 —— 否则 `:LspRestart` 后 `foldexpr` 仍指向 lsp 表达式, 它无 state 时每行返回 0, 折叠静默失效, 见 `docs/code-review-2026-10-02.md` 的 BUG-06)。**不要在别处直接写 `foldexpr`** —— `viewoptions='folds'` 让 `loadview` 在 `BufWinEnter` 恢复 view 里的旧 `foldexpr`, 时序上它晚于 FileType、早于异步的 `LspAttach`, 会把 treesitter 的值顶掉(表现为折叠静默失效, 见 `docs/code-review-2026-10-01.md` 的 BUG-02), 所以 `base.lua` 在 `loadview` 之后必须再调一次 `refresh()`。该模块只写 `foldmethod`/`foldexpr`, 不碰 `foldenable`/`foldlevel`, 以保留"记住折叠"(`foldenable` 初值在 `treesitter.lua` 的 FileType 里设, 属初始化不属裁决)。

## 外部依赖(不在本仓库)

可执行文件由 `/etc/nixos/home/shell/nvim.nix` 的 home-manager 声明: clangd、lua-language-server、nixd、marksman、ruff、basedpyright、guile-lsp-server、rust-analyzer、typescript-language-server、haskell-language-server、ormolu、nixfmt、prettierd、taplo、texlab、tinymist, 格式化工具 stylua、clang-format、rustfmt(见 `lua/plugins/conform.lua`; latexindent 不在此处 —— 它来自可选的 `home/desktop/applications.nix` 的 texliveFull, 移走该模块后 tex 格式化会静默降级), 以及 telescope 用的 ripgrep/fd 等。旧独立仓库(gitee `nvim-dotfiles`)的 README/LICENSE 未并入本仓库, 历史说明去那边查; 缺工具时报告用户, 不要 `sudo` 安装(系统缺的临时工具用 `nix shell`)。

其它环境耦合: `guicursor` 只发闪烁序列, 动画由终端控制(kitty `cursor_blink_interval`); 未设置 `unnamedplus`, 系统剪贴板依赖终端/wl-clipboard; `j/k` 已与 `gj/gk` 对调, 新增移动类映射时注意。

## 风格

- 注释、README、commit 一律中文。commit 形如 `type(scope): 中文描述`(历史前缀拼写不统一, 如 `chorn`/`chron`, 不必模仿错拼)。
- 模块统一 `local M = {}` / `local module = {}` 加 `return`, 文件头常有 `--- <name>.lua` 与用法说明; 注释解释"为什么"而非复述代码。
- Lua 的缩进/引号风格由本目录的 `.stylua.toml` 唯一决定(4 空格 + 单引号): 保存时会跑 conform→stylua, 手工调风格会在下次保存被改回; 要改风格就改那个文件。
- 改动保持最小, 不做任务外重构; 与相邻文件风格保持一致。
