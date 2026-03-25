{ config, pkgs, ... }:

{
	imports = [
        ./dev/git.nix
        ./dev/lazygit.nix
        ./dev/haskell.nix
        ./dev/python.nix
	];

    # --- --- --- 其它开发环境相关的程序 --- --- ---
    home.packages = with pkgs; [
        # 系统调用的 trace 工具
        strace
        # Rust 工具链安装器
        rustup
        # bash 的编译构建工具
        argc
	# --- 开发必备工具链 ---
	gcc           # 提供 C 编译器 (cc, gcc)，解决 Neovim 报错
	gnumake       # 很多插件编译时需要用到 make
	binutils      # 提供 ld, ar 等二进制工具
	  
	# --- Node.js 环境 ---
	nodejs        # 包含 node 和 npm，解决 zsh 找不到 npm 的问题
    ];
}

