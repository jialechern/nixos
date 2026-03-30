{ config, pkgs, ... }:

{
  programs.btop = {
    enable = true;

    # =========================================================
    # btop 核心配置
    # =========================================================
    settings = {
      # 主题名称，和下面 themes 里的名字对应
      color_theme = "nord";

      # 是否显示主题背景；false 适合终端透明背景
      theme_background = false;

      # 开启真彩色
      truecolor = true;

      # 是否启用 Vim 风格按键
      vim_keys = true;

      # 默认图表符号；braille 细节最高
      graph_symbol = "braille";

      # 刷新间隔（毫秒）；官方文档里 2000ms 或更高更合适
      update_ms = 2000;

      # 进程排序方式
      proc_sorting = "cpu lazy";

      # 默认显示哪些面板
      shown_boxes = "cpu mem net proc";
    };

    # =========================================================
    # btop 主题文件
    #   位于 `$XDG_CONFIG_HOME/btop/themes/nord.theme`
    # =========================================================
    themes = {
      nord = ''
        # Nord 风格主题
        # 颜色格式可以是 #RRGGBB

        theme[main_bg]="#2E3440"
        theme[main_fg]="#D8DEE9"
        theme[title]="#8FBCBB"
        theme[hi_fg]="#5E81AC"
        theme[selected_bg]="#4C566A"
        theme[selected_fg]="#ECEFF4"
        theme[inactive_fg]="#4C566A"
        theme[proc_misc]="#5E81AC"
        theme[cpu_box]="#4C566A"
        theme[mem_box]="#4C566A"
        theme[net_box]="#4C566A"
        theme[proc_box]="#4C566A"
      '';
    };
  };
}
