{ config, pkgs, lib, dotfilesRoot, ... }:

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
    nixpkgs-fmt
    basedpyright
    black
    guile-lsp-server
    rust-analyzer
    typescript-language-server
    prettierd
    taplo
    texlab
    tinymist
  ];
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

    # --- 使用 nix/home-manager 管理 neovim 插件 ---
    plugins = with pkgs.vimPlugins; [
    ];

    # 将依赖注入 Neovim 的 PATH
    extraPackages = lspDeps ++ extraTools;

    # 不再写入 ${config.home.homeDirectory}/.config/nvim/init.lua, 避免和自己的配置文件冲突
    sideloadInitLua = true;
  };

  # 链接 Lua 配置文件夹
  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/nvim";
    force = true;
  };
}
