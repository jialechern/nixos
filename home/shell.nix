{ config, pkgs, ... }:

{
  imports = [
    ./shell/bash.nix
    ./shell/fish.nix
    ./shell/zsh.nix
    ./shell/btop.nix
    ./shell/htop.nix
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
    ./shell/pandoc.nix
    ./shell/fastfetch.nix
    ./shell/proxychains.nix
    ./shell/yt-dlp.nix
    ./shell/jq.nix
  ] ++ (builtins.filter builtins.pathExists [
    # neovim 配置
    ./shell/nvim.nix
  ]);

  # --- --- --- 其它 Shell 工具 --- --- ---
  home.packages = with pkgs; [
    wget
    curl
    ffmpeg

    # nixos 安装工具
    nixos-install-tools
    # 压缩/解压缩工具
    zip
    unzip
    # ip 扫描工具
    nmap
    # yaml toml xml 等文件的命令行解析工具
    yq
    # 动态链接软件的分流代理工具
    proxychains-ng
    # OCR 工具
    ocrmypdf
    # 将 Nix 命令的输出处理以显示有用且美观的信息的工具
    nix-output-monitor
    # 命令行艺术字体生成工具
    figlet
    cmatrix
    # pdf 处理工具
    poppler-utils
    python3Packages.pdf2docx
    img2pdf
  ];
}
