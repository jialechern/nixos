{ pkgs, ... }:

let
  extraTools = with pkgs; [
    ripgrep
    fd
    nodejs

    zathura

    # nvim 运行时实际调用的命令行工具:
    #   git     -> telescope 的 git_* picker 与 FilesCwd 里的 git rev-parse
    #   gcc     -> after/ftplugin/{c,cpp}.lua 的 makeprg(g++ 同包)
    #   gnumake -> after/ftplugin/make.lua 与各语言 <C-e> 走的 :make
    #   lua5_4  -> after/ftplugin/lua.lua 的 makeprg(系统并没有独立的 lua 解释器;
    #              想要 LuaJIT 语义就换成 luajit)
    git
    gcc
    gnumake
    lua5_4
  ];

  lspDeps = with pkgs; [
    haskell-language-server
    ormolu
    clang-tools
    lua-language-server
    marksman
    nixd
    nixfmt
    basedpyright
    black
    guile-lsp-server
    rust-analyzer
    typescript-language-server
    prettierd
    # ruff 由 home/dev/python.nix 提供, 这里显式声明以免那里的改动悄悄破坏 lsp/ruff.lua
    ruff
    taplo
    texlab
    tinymist
  ];

  # nvim-treesitter 的全部 parser 二进制(仓库 settings/treesitter.lua 只用到其中 26 种)
  # 想缩小闭包就换成只列用到的那几个:
  #   bash c cpp css go html java javascript json lua markdown markdown_inline nix python
  #   rust toml typescript vim vimdoc yaml zsh typst latex haskell scheme
  # (新增语言时两边都要加: 这里 + settings/treesitter.lua 的 filetypes)
  treesitterParsers = pkgs.lib.filter pkgs.lib.isDerivation
    (pkgs.lib.attrValues pkgs.vimPlugins.nvim-treesitter.parsers);

  # 把各 grammar derivation 里自带、但打包时被丢掉的 queries/ 汇总起来
  treesitterQueries = pkgs.runCommand "nvim-treesitter-queries" { } ''
    mkdir -p $out
    if [ -d ${pkgs.vimPlugins.nvim-treesitter}/runtime/queries ]; then
      cp -r ${pkgs.vimPlugins.nvim-treesitter}/runtime/queries $out/queries
    else
      cp -r ${pkgs.vimPlugins.nvim-treesitter}/queries $out/queries
    fi
  '';

  # neovim 插件(optional = true 的进 pack/hm/opt, 由仓库里 vim.cmd.packadd('<目录名>') 按需加载;
  # 不写 optional 的进 start, 启动即加载 —— 两个 treesitter 包必须留在 start)
  nvimPlugins = with pkgs.vimPlugins; [
    # 主题插件
    { plugin = catppuccin-nvim;   optional = true; }
    # 状态栏插件
    { plugin = lualine-nvim;      optional = true; }
    # UI 插件
    { plugin = noice-nvim;        optional = true; }
    { plugin = nui-nvim;          optional = true; }
    # 文本对齐插件
    { plugin = vim-easy-align;    optional = true; }
    # 模糊搜索插件
    { plugin = telescope-nvim;             optional = true; }
    { plugin = plenary-nvim;               optional = true; }
    { plugin = telescope-fzf-native-nvim;  optional = true; }
    # Snippet/LSP
    { plugin = nvim-lspconfig;   optional = true; }
    { plugin = mini-snippets;    optional = true; }
    { plugin = friendly-snippets; optional = true; }
  ];
in
{
  # home.packages 让这些工具在 shell 里也能直接用(AGENTS.md 的离线类型检查等要用);
  # programs.neovim.extraPackages 另外把它们写进 nvim 进程的 PATH —— 从桌面启动器这类
  # 没有登录 shell PATH 的环境启动时也能找到 rg/fd/gcc, 两者不能只留一侧。
  home.packages = lspDeps ++ extraTools;

  programs.neovim = {
    enable = true;

    defaultEditor = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    withPython3 = false;
    withNodeJs = false;
    withRuby = false;

    # 语言 parser 和插件扩展
    plugins = treesitterParsers ++ [ treesitterQueries ] ++ nvimPlugins;

    # 将依赖注入 Neovim 的 PATH
    extraPackages = lspDeps ++ extraTools;

    # 不再写入 ${config.home.homeDirectory}/.config/nvim/init.lua, 避免和自己的配置文件冲突
    sideloadInitLua = true;
  };
}
