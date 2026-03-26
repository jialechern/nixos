{ config, pkgs, lib, ... }:

let
  nvimPath = /etc/nixos/home/nvim;

  extraTools = with pkgs; [
    ripgrep
    fd
    bat
    nodejs
    yarn
    cargo
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
    haskell-language-server ormolu
    clang-tools
    lua-language-server
    marksman
    nixd nixpkgs-fmt
    pyright black
    rust-analyzer 
    typescript-language-server prettierd
    taplo
    texlab tinymist typst
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

    # --- 使用 nix/home-manager 管理 neovim 插件 ---
    plugins = with pkgs.vimPlugins; [
    ];

    # 将依赖注入 Neovim 的 PATH
    extraPackages = lspDeps ++ extraTools;
  };

  # 链接你的 Lua 配置文件夹
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;
}
