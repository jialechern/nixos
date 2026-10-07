{ config, pkgs, ... }:

{
  imports = [
    # bash/zsh/fish 共享的别名、函数与 PATH
    ./shell/common.nix

    # niri-gpu 诊断命令 (ngpu 别名依赖它; 从 common.nix 拆出以保持职责单一)
    ./shell/niri-gpu.nix

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
  ]
  ++ (builtins.filter builtins.pathExists [
    # neovim 配置 (pathExists 只看 git 已索引的文件: 新增后必须先 git add)
    ./shell/nvim.nix
  ]);

  # --- --- --- 其它 Shell 工具 --- --- ---
  home.packages = with pkgs; [
    # wget / curl 已在系统侧 (modules/software_and_tool.nix), 不再重复装
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
    # 将 Nix 命令的输出处理以显示有用且美观的信息的工具
    nix-output-monitor
    # 命令行艺术字体生成工具
    figlet
    cmatrix
    # pdf/文档 工具 (非 skill 依赖)
    poppler-utils # pdf 工具集
    img2pdf # 图片无损封包成 pdf
    ocrmypdf # OCR 工具
  ];
}
