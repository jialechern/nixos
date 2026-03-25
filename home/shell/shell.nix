{ config, pkgs, ... }:

{
	imports = [
		./bash.nix
		./fish.nix
		./zsh.nix
        ./tmux.nix
		./starship.nix
		./zoxide.nix
        ./eza.nix
        ./fd.nix
        ./ripgrep.nix
        ./procs.nix
        ./dust.nix
        ./fzf.nix
        ./yazi.nix
        ./bat.nix
	    ./fastfetch.nix
        ./proxychains.nix
	];

    # --- --- --- 其它 Shell 工具 --- --- ---
    home.packages = with pkgs; [
        wget
        curl
        # yaml toml xml 等文件的命令行解析工具
        yq
        # 动态链接软件的分流代理工具
        proxychains-ng
        # OCR 工具
        ocrmypdf
    ];
}
