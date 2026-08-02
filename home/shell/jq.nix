{ config, pkgs, ... }:
{
  # ── jq: JSON 命令行处理器 ──
  programs.jq = {
    enable = true;
    # 使用默认 jq 包(pkgs.jq), null 表示默认
    # 如需指定版本可改为 pkgs.jq 或 pkgs.jq.override { … }
    package = pkgs.jq;
    # 自定义 JSON 彩色输出(Catppuccin Mocha 配色, 适配暗色终端)
    # 格式见 https://jqlang.github.io/jq/manual/#Colors
    # jq 仅支持 SGR 转义序列, 这里用 24 位真彩色 (38;2;r;g;b) 精确表达 Mocha 色值
    colors = {
      # null 值: Mocha Overlay1 (#6f7585), 低调不抢眼
      null = "38;2;111;117;133";
      # false: Mocha Red (#f38ba8), 与错误/否定语义一致
      false = "38;2;243;139;168";
      # true: Mocha Green (#a6e3a1), 与正确/肯定语义一致
      true = "38;2;166;227;161";
      # 数字: Mocha Peach (#fab387), 温暖醒目
      numbers = "38;2;250;179;135";
      # 字符串: Mocha Green (#a6e3a1)
      strings = "38;2;166;227;161";
      # 数组外壳 []: Mocha Teal (#94e2d5), 结构清晰突出
      arrays = "38;2;148;226;213";
      # 对象外壳 {}: Mocha Mauve (#cba6f7), 结构清晰突出
      objects = "38;2;203;166;247";
      # 对象键名: Mocha Blue (#89b4fa)
      objectKeys = "38;2;137;180;250";
    };
  };
  # ── jqp: jq 交互式 TUI (可选配套) ──
  programs.jqp = {
    enable = true;
    package = pkgs.jqp;
    settings = {
        # 主题配置
        theme = {
          # chroma 内置主题名; 语法与 UI 颜色在下方全部覆盖为 Mocha 配色
          name = "nord";
          # ── 语法高亮颜色覆盖 (Catppuccin Mocha) ──
          # chroma Token 短名参考:
          #   https://github.com/alecthomas/chroma/blob/master/types.go#L210-L308
          # JSON 词法规则参考:
          #   https://github.com/alecthomas/chroma/blob/master/lexers/embedded/json.xml
          chromaStyleOverrides = {
            # 键名: Mocha Blue (#89b4fa) + 下划线
            kc = "#89b4fa underline";
            # 字符串值: Mocha Green (#a6e3a1)
            str = "#a6e3a1";
            # 数字: Mocha Peach (#fab387)
            num = "#fab387";
            # true/false/null: Mocha Mauve (#cba6f7)
            nl = "#cba6f7";
          };
          # ── UI 非语法元素颜色覆盖 (Catppuccin Mocha) ──
          # 五个固定字段, 对应 jqp 界面的不同区域文字色
          styleOverrides = {
            # 主文字色: Mocha Text (#cdd6f4)
            primary = "#cdd6f4";
            # 次要文字(状态栏等): Mocha Overlay0 (#7f849c)
            secondary = "#7f849c";
            # 错误/警告文字: Mocha Red (#f38ba8)
            error = "#f38ba8";
            # 非活跃区域文字: Mocha Surface1 (#45475a)
            inactive = "#45475a";
            # 成功/运行完成文字: Mocha Green (#a6e3a1)
            success = "#a6e3a1";
          };
      };
    };
  };
}
