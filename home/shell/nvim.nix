{ pkgs, ... }:

let
  extraTools = with pkgs; [
    ripgrep
    fd
    nodejs

    zathura

    # nvim 运行时实际调用的命令行工具:
    git
    gcc
    gnumake
  ];

  lspDeps = with pkgs; [
    haskell-language-server
    ormolu
    clang-tools
    lua-language-server
    stylua
    marksman
    nixd
    nixfmt
    basedpyright
    guile-lsp-server
    rust-analyzer
    typescript-language-server
    prettierd
    ruff
    taplo
    texlab
    tinymist
  ];

  # nvim-treesitter 的全部 parser 二进制(配置实际只用其中一部分, 见下面的列表)
  # 想缩小闭包就换成只列用到的那几个:
  #   bash c cpp css go html java javascript json lua markdown markdown_inline nix python
  #   rust toml typescript vim vimdoc yaml zsh typst latex haskell scheme
  # (新增语言时两边都要加: 这里 + home/shell/nvim/lua/settings/treesitter.lua 的 filetypes)
  treesitterParsers = pkgs.lib.filter pkgs.lib.isDerivation (
    pkgs.lib.attrValues pkgs.vimPlugins.nvim-treesitter.parsers
  );

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
    {
      plugin = catppuccin-nvim;
      optional = true;
    }
    # 状态栏插件
    {
      plugin = lualine-nvim;
      optional = true;
    }
    # UI 插件
    {
      plugin = noice-nvim;
      optional = true;
    }
    {
      plugin = nui-nvim;
      optional = true;
    }
    # 模糊搜索插件
    {
      plugin = telescope-nvim;
      optional = true;
    }
    {
      plugin = plenary-nvim;
      optional = true;
    }
    {
      plugin = telescope-fzf-native-nvim;
      optional = true;
    }
    # Snippet/LSP
    {
      plugin = nvim-lspconfig;
      optional = true;
    }
    {
      plugin = mini-snippets;
      optional = true;
    }
    {
      plugin = friendly-snippets;
      optional = true;
    }
    # 格式化
    {
      plugin = conform-nvim;
      optional = true;
    }
  ];

  # 部署树: 复制仓库里的 neovim 配置, 构建期做 lua 语法检查并去掉仓库内部文档。
  # 写法对齐 home/desktop/niri.nix 的 niriConfig —— 语法写错时 rebuild 直接失败,
  # 而不是重启 nvim 才发现; 生成的是只读 store 树, 由下方 xdg.configFile 部署。
  nvimConfig = pkgs.runCommand "nvim-config-checked"
    {
      nativeBuildInputs = with pkgs; [
        luajit
        findutils
      ];
    }
    ''
      cp -r ${./nvim} $out
      chmod -R u+w $out
      # AGENTS.md 是仓库内部文档, 不部署到 ~/.config/nvim
      rm -f $out/AGENTS.md
      # 全部 lua 文件过一遍字节码编译(等价于语法检查; luajit 与 nvim 内置版本同源)
      find $out -name '*.lua' -print0 | xargs -0 -n1 luajit -bl > /dev/null
      echo "checked $(find $out -name '*.lua' | wc -l) lua files"
    '';
in
{
  # --- --- --- 部署 neovim 配置 --- --- ---
  # 源是仓库里的 home/shell/nvim/(经上面 nvimConfig 校验后产出的只读 store 树),
  # recursive = true 让它逐文件软链到 ~/.config/nvim —— 因此改配置必须 rebuild,
  # 且 ~/.config/nvim 里的文件不可就地编辑(免 rebuild 试配置见 home/shell/nvim/AGENTS.md 的验证段)。
  xdg.configFile."nvim" = {
    source = nvimConfig;
    recursive = true;
  };

  # home.packages 让这些工具在 shell 里也能直接用(home/shell/nvim/AGENTS.md 的离线类型检查等要用);
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

    # 必须保持 true: nix 侧的 cfg.initLua(luajit 的 package.path/cpath + 关闭 provider)由 wrapper
    # 以 --cmd 'lua dofile(...)' 注入; 设成 false 时 HM 会把它写成 ~/.config/nvim/init.lua
    # (HM modules/programs/neovim/default.nix: enable = !sideloadInitLua), 与上面
    # xdg.configFile."nvim" 里仓库自带的 init.lua 同目标冲突。
    sideloadInitLua = true;
  };
}
