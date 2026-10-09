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
    rustfmt
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

  # --- --- --- 本机热调试通道 --- --- ---
  # ~/.config/nvim/after/plugin/local-live.lua 是 nvim 启动时自动 source 的最后一个
  # 挂载点(runtimepath 末尾的 after/), 由 tmpfiles 建成**可写实体文件** —— 它不在
  # flake 里, 不受构建期 luajit 检查约束, 改完用 :luafile % 或 :restart 生效,
  # 不需要 rebuild。用法与骨架见 home/shell/nvim/AGENTS.md。
  systemd.user.tmpfiles.rules = [
    "f %h/.config/nvim/after/plugin/local-live.lua 0644 - - -"
  ];

  # 仓库里若手写了同名文件, 上面的 xdg.configFile(recursive) 会用只读软链把它顶掉,
  # 热调试通道静默失效。HM 自带的重复目标断言看不到递归目录源内部的文件, 故自建守卫
  # (niri.nix 对 local-override.kdl 有同样的断言)。
  assertions = [
    {
      assertion = !(builtins.pathExists ./nvim/after/plugin/local-live.lua);
      message = ''
        请勿在仓库中手写 home/shell/nvim/after/plugin/local-live.lua:
        它由本模块的 tmpfiles 规则创建为可写的热调试文件, 同名仓库文件会以只读软链静默顶掉它。
      '';
    }
  ];

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
