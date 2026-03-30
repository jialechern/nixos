{ config, pkgs, ... }:

{
	imports = [
		./shell/bash.nix
		./shell/fish.nix
		./shell/zsh.nix
        ./shell/btop.nix
        ./shell/tmux.nix
		./shell/starship.nix
		./shell/zoxide.nix
        ./shell/eza.nix
        ./shell/fd.nix
        ./shell/ripgrep.nix
        ./shell/procs.nix
        ./shell/dust.nix
        ./shell/fzf.nix
        ./shell/yazi.nix
        ./shell/bat.nix
	    ./shell/fastfetch.nix
        ./shell/proxychains.nix
	];

    # --- --- --- 其它 Shell 工具 --- --- ---
    home.packages = with pkgs; [
        wget
        curl
        ffmpeg
        # yaml toml xml 等文件的命令行解析工具
        yq
        # 动态链接软件的分流代理工具
        proxychains-ng
        # OCR 工具
        ocrmypdf
    ];
}
