{ config, pkgs, ... }:

{
  programs.btop = {
    enable = true;

    # =========================================================
    # btop 核心配置
    # =========================================================
    settings = {
      # 主题名称，和下面 themes 里的名字对应
      color_theme = "catppuccin_mocha";

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
    #   位于 `$XDG_CONFIG_HOME/btop/themes/catppuccin_mocha.theme`
    #   内容取自官方 Catppuccin 仓库 (catppuccin/btop)
    # =========================================================
    themes = {
      catppuccin_mocha = ''
        # Catppuccin Mocha 官方主题 (https://github.com/catppuccin/btop)
        # 颜色格式可以是 #RRGGBB

        # 主背景, 终端默认背景则为空; 透明背景需留空
        theme[main_bg]="#1e1e2e"

        # 主文字颜色
        theme[main_fg]="#cdd6f4"

        # 标题颜色
        theme[title]="#cdd6f4"

        # 快捷键高亮颜色
        theme[hi_fg]="#89b4fa"

        # 进程列表中选中项的背景色
        theme[selected_bg]="#45475a"

        # 进程列表中选中项的前景色
        theme[selected_fg]="#89b4fa"

        # 非活跃/禁用文字颜色
        theme[inactive_fg]="#7f849c"

        # 图表上文字颜色, 如 uptime 与网络图表缩放文字
        theme[graph_text]="#f5e0dc"

        # 百分比仪表背景色
        theme[meter_bg]="#45475a"

        # 进程框杂项颜色, 含迷你 CPU 图、内存详情图和详情状态文字
        theme[proc_misc]="#f5e0dc"

        # CPU、内存、网络、进程框轮廓颜色
        theme[cpu_box]="#cba6f7" # Mauve
        theme[mem_box]="#a6e3a1" # Green
        theme[net_box]="#eba0ac" # Maroon
        theme[proc_box]="#89b4fa" # Blue

        # 框分隔线与小框线颜色
        theme[div_line]="#6c7086"

        # 温度图颜色 (绿 -> 黄 -> 红)
        theme[temp_start]="#a6e3a1"
        theme[temp_mid]="#f9e2af"
        theme[temp_end]="#f38ba8"

        # CPU 图颜色 (Teal -> Lavender)
        theme[cpu_start]="#94e2d5"
        theme[cpu_mid]="#74c7ec"
        theme[cpu_end]="#b4befe"

        # 内存/磁盘空闲条 (Mauve -> Lavender -> Blue)
        theme[free_start]="#cba6f7"
        theme[free_mid]="#b4befe"
        theme[free_end]="#89b4fa"

        # 内存/磁盘缓存条 (Sapphire -> Lavender)
        theme[cached_start]="#74c7ec"
        theme[cached_mid]="#89b4fa"
        theme[cached_end]="#b4befe"

        # 内存/磁盘可用条 (Peach -> Red)
        theme[available_start]="#fab387"
        theme[available_mid]="#eba0ac"
        theme[available_end]="#f38ba8"

        # 内存/磁盘已用条 (Green -> Sky)
        theme[used_start]="#a6e3a1"
        theme[used_mid]="#94e2d5"
        theme[used_end]="#89dceb"

        # 下载图颜色 (Peach -> Red)
        theme[download_start]="#fab387"
        theme[download_mid]="#eba0ac"
        theme[download_end]="#f38ba8"

        # 上传图颜色 (Green -> Sky)
        theme[upload_start]="#a6e3a1"
        theme[upload_mid]="#94e2d5"
        theme[upload_end]="#89dceb"

        # 进程框线程/内存/CPU 使用率渐变 (Sapphire -> Mauve)
        theme[process_start]="#74c7ec"
        theme[process_mid]="#b4befe"
        theme[process_end]="#cba6f7"
      '';
    };
  };
}
