{ config, pkgs, lib, ... }:

let
    nvimPath = /etc/nixos/modules/nvim;
    deps = with pkgs; [
        # --- LSP 服务器 ---
        # Haskell LSP
        haskell-language-server
        # Haskell fomatter
        ormolu

        # C/C++
        clang-tools
        
        # Lua
        lua-language-server
        
        # Markdown
        marksman
        
        # Nix
        nixd
        nixpkgs-fmt	 # 格式化工具
        
        # Python
        pyright
        # Python fomatter
        black
        
        # 这个包中包含了 rust-analyzer
        rustup

        # Typescript
        typescript-language-server
        # Typescript/Javascript fomatter
        prettierd
        
        # TOML
        taplo
        
        # LaTeX & Typst
        texlab
        tinymist
        typst

        # --- 其它 neovim 依赖的外部工具 ---
        tree-sitter
	];
in
{
    # --- --- --- 安装外部依赖 --- --- ---
    home.packages = deps;

    # --- --- --- neovim 基础配置 --- --- ---
	programs.neovim = {
		enable = true;

        # 设置为默认编辑器
		defaultEditor = true;

        # 创建 vi/vim 别名
		viAlias = true;
		vimAlias = true;

        # --- --- --- 外部依赖 --- --- ---
		extraPackages = deps;
	};

    # --- --- --- 链接 nvim 配置目录 --- --- ---

    # xdg.configFile."nvim" = lib.mkIf (builtins.pathExists nvimPath) {
    #     source = config.lib.file.mkOutOfStoreSymlink nvimPath;
    # };

    xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;
}
