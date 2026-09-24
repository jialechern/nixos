{ pkgs, ... }:

let
  extraTools = with pkgs; [
    ripgrep
    fd
    bat
    nodejs
    yarn
    fzf

    zathura

    # vimtex 的反向搜索依赖
    xdotool

    # nvim-treesitter 插件需要
    git
    gcc
    gnumake
    tree-sitter
  ];

  lspDeps = with pkgs; [
    haskell-language-server
    ormolu
    clang-tools
    lua-language-server
    marksman
    nixd
    nixpkgs-fmt # 已归档 (最后更新 2024-07), 官方 formatter 是 nixfmt (RFC 166)
    # nixfmt
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

  # nvim-treesitter 的全部 parser 二进制
  treesitterParsers = pkgs.lib.filter pkgs.lib.isDerivation
    (pkgs.lib.attrValues pkgs.vimPlugins.nvim-treesitter.parsers);
in
{
  # 安装外部依赖到系统环境
  home.packages = lspDeps ++ extraTools;

  programs.neovim = {
    enable = true;

    defaultEditor = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    # neovim 插件本体由 ${config.home.homeDirectory}/.config/nvim 里的 vim.pack 管理, 这里只注入
    # treesitter parser (见 treesitterParsers)
    plugins = treesitterParsers;

    # 将依赖注入 Neovim 的 PATH
    extraPackages = lspDeps ++ extraTools;

    # 不再写入 ${config.home.homeDirectory}/.config/nvim/init.lua, 避免和自己的配置文件冲突
    sideloadInitLua = true;
  };
}
