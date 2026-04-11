{ config, pkgs, ... }:

let
  myPreviewer = pkgs.writers.writePython3Bin "fzf-previewer"
    {
      libraries = [
        pkgs.python3Packages.python-magic
        pkgs.python3Packages.pillow
      ];
      # 禁用严格的 flake8 格式检查
      doCheck = false;
    }
    (builtins.readFile ../../scripts/fzf-previewer); # 预览脚本位置

  defaultConfig = [
    # "--height 80%"
    "--style=full"
    "--layout=reverse"
    "--border"
    "--info=inline"
    "--prompt='λ '"
    "--pointer='▶'"
    "--marker='✓'"
    "--color='bg+:-1,fg:gray,fg+:white,hl:yellow,hl+:yellow'"
    "--color='pointer:bright-blue,marker:bright-green,header:bright-cyan'"
    "--bind 'ctrl-/:change-preview-window(50%|hidden|)'"

    # 注入预览脚本路径 
    "--preview '${myPreviewer}/bin/fzf-previewer {}'"

    # --- 按键绑定 ---
    "--bind='ctrl-a:select-all'"
    "--bind='ctrl-u:deselect-all'"
    "--bind='ctrl-r:toggle-all'"
    "--bind='ctrl-s:toggle-sort'"
    "--bind='ctrl-l:last'"
    "--bind='ctrl-f:first'"
    "--bind='ctrl-n:half-page-down'"
    "--bind='ctrl-p:half-page-up'"
    "--bind='ctrl-j:down'"
    "--bind='ctrl-k:up'"
    "--bind='ctrl-d:preview-down'"
    "--bind='ctrl-t:toggle-preview'"
  ];

in
{
  programs.fzf = {
    enable = true;

    # 启用 Shell 支持
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    # 启用 fzf 时使用的默认命令
    defaultCommand = "fd --type file --color=always --follow --strip-cwd-prefix --hidden --exclude .git";

    # # 使用 Alt+c 更改工作目录是使用的命令
    changeDirWidgetCommand = "fd --type directory --color=always --follow --strip-cwd-prefix --hidden --exclude .git";

    # # 使用 Alt+c 更改工作目录是使用的 fzf 选项
    changeDirWidgetOptions = defaultConfig;

    # 使用 Ctrl+t 时使用的默认命令
    fileWidgetCommand = "fd --type file --color=always --follow --strip-cwd-prefix --hidden --exclude .git";

    # 启用 tmux 支持
    tmux.enableShellIntegration = true;

    # # 启用 tmux 支持时运行 fzf 的选项
    # tmux.shellIntegrationOptions = [];

    # 默认配置
    defaultOptions = defaultConfig;

    # 使用 Ctrl+r 时搜索历史时的 fzf 选项
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

  # --- --- --- 依赖程序 --- --- ---
  home.packages = with pkgs; [
    chafa
    file
  ];
}
