{ config, pkgs, ... }:

{
  imports = [
    # bash/zsh/fish 共享的别名、函数与 PATH
    ./shell/common.nix

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
    # 将 Nix 命令的输出处理以显示有用且美观的信息的工具
    nix-output-monitor
    # 命令行艺术字体生成工具
    figlet
    cmatrix
    # pdf/文档 工具 (非 skill 依赖)
    poppler-utils # pdf 工具集
    img2pdf # 图片无损封包成 pdf
    ocrmypdf # OCR 工具

    # --- PDF skill 配套 CLI ---
    # 来源: ~/.agents/skills 的 pdf (anthropics/skills 官方) 与 pdf-parser
    # (memtomem), 见 home/skills.nix; python 侧配套库在 home/dev/python.nix,
    # 两层按 skill 文档分工安装, 不要重复
    # poppler-utils # [pdf] pdftotext/pdftoppm/pdfimages: 抽文本/页面渲染成图/抽内嵌图; 也是 pdf2image 的渲染后端
    qpdf # [pdf] 命令行 合并/拆分/旋转/加解密/修复 (skill 提及的 pdftk 已老化, 由 qpdf 取代, 不装)
    (tesseract5.override {
      # [pdf] OCR 引擎 (pytesseract/pdf2image 的后端, 扫描件转写用);
      # 顺带满足 [pdf-parser] 的可选 OCR 分支;
      # eng 为 nixpkgs wrapper 强制要求, osd+chi_sim+chi_tra 覆盖中英/简繁, 按需增删
      enableLanguages = [ "eng" "osd" "chi_sim" "chi_tra" ];
    })
  ];
}
