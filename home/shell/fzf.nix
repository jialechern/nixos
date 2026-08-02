{ config, pkgs, ... }:

let
  myPreviewer = pkgs.writers.writePython3Bin "fzf-previewer"
    {
      libraries = [
        pkgs.python3Packages.python-magic
        pkgs.python3Packages.pillow
      ];
      doCheck = false;
    }
    (builtins.readFile ./fzf/fzf-previewer); # 预览脚本位置

  # 通用 fzf 默认选项, 应用于所有 fzf 调用(包括 Ctrl+T、Alt+C)
  defaultConfig = [
    # --- 外观 ---
    "--style=full" # 完整样式
    "--layout=reverse" # 列表从上到下排列(提示符在顶部)
    "--border=rounded" # 直角边框
    "--info=inline" # 匹配计数内联显示在提示符旁
    "--prompt='λ '" # 提示符
    "--pointer='▶'" # 当前行指针
    "--marker='✓'" # 多选标记
    "--color='bg+:-1,fg:gray,fg+:white,hl:yellow,hl+:yellow'"
    "--color='pointer:bright-blue,marker:bright-green,header:bright-cyan'"

    # --- 预览窗口 ---
    "--preview-window='right,60%,border-sharp,wrap'" # 右侧 60%、直角边框、自动换行
    "--preview='${myPreviewer}/bin/fzf-previewer {}'"
    "--bind='ctrl-/:change-preview-window(right,60%|hidden|right,80%)'" # 切换预览: 60%/隐藏/80%

    # --- 交互行为 ---
    "--multi" # 启用多选模式(Tab/Shift-Tab 选中)
    "--cycle" # 列表可循环滚动
    "--scroll-off=5" # 滚动到底/顶时保留 5 行上下文
    "--highlight-line" # 高亮整行(而非仅高亮匹配子串)
    "--tiebreak=length,chunk,begin,index" # 同分排序: 短行优先 > 匹配块 > 匹配位置 > 原始顺序
    "--filepath-word" # 按路径分隔符进行词级移动

    # --- 按键绑定 ---
    "--bind='ctrl-j:down'"
    "--bind='ctrl-k:up'"
    "--bind='ctrl-o:toggle'" # 你的自定义键
    "--bind='tab:toggle+down'" # 选中当前条目并下移
    "--bind='shift-tab:toggle+up'" # 取消选中并上移
    # 多选操作
    "--bind='ctrl-a:select-all'" # 全选
    "--bind='ctrl-d:deselect-all'" # 取消全选
    "--bind='ctrl-r:toggle-all'" # 反选
    # 排序切换
    "--bind='ctrl-s:toggle-sort'"
    # 跳转到首尾
    "--bind='ctrl-l:last'" # 跳到最后一项
    "--bind='ctrl-f:first'" # 跳到第一项
    # 半页翻页
    "--bind='ctrl-n:half-page-down'"
    "--bind='ctrl-p:half-page-up'"
    # 预览窗口滚动
    "--bind='ctrl-alt-j:preview-down'"
    "--bind='ctrl-alt-k:preview-up'"
    # 预览窗口显隐
    "--bind='ctrl-t:toggle-preview'"
  ];

in
{
  programs.fzf = {
    enable = true;

    # Shell 集成
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    # 默认搜索命令
    defaultCommand = "fd --type file --follow --strip-cwd-prefix --hidden --exclude .git";

    # Alt+C 切换工作目录时使用的命令与 fzf 选项
    changeDirWidget = {
      command = "fd --type directory --follow --strip-cwd-prefix --hidden --exclude .git";
      options = defaultConfig;
    };

    # Ctrl+T 搜索文件时使用的命令与 fzf 选项
    fileWidget = {
      command = "fd --type file --follow --strip-cwd-prefix --hidden --exclude .git";
      options = defaultConfig;
    };

    # Ctrl+R 搜索历史命令时的 fzf 选项
    historyWidget = {
      options = [
        "--sort" # 按匹配质量排序
        "--exact" # 精确匹配
      ];
    };

    # Tmux 集成
    tmux.enableShellIntegration = true;

    # 所有 fzf 调用的默认选项
    defaultOptions = defaultConfig;
  };

  # 预览脚本所需依赖
  home.packages = with pkgs; [
    bat # 代码语法高亮预览
    chafa # 终端图片预览
    eza # 目录树预览(替代 ls)
    file # 文件类型检测
  ];
}
