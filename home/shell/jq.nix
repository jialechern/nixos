{ config, pkgs, ... }:
{
  # ── jq: JSON 命令行处理器 ──
  programs.jq = {
    enable = true;
    # 使用默认 jq 包(pkgs.jq), null 表示默认
    # 如需指定版本可改为 pkgs.jq 或 pkgs.jq.override { … }
    package = pkgs.jq;
    # 自定义 JSON 彩色输出(Nord 主题适配暗色终端)
    # 格式见 https://jqlang.github.io/jq/manual/#Colors
    colors = {
      # null 值: 粗体暗灰, 低调不抢眼
      null = "1;30";
      # false: 红色, 与错误/否定语义一致
      false = "0;31";
      # true: 绿色, 与正确/肯定语义一致
      true = "0;32";
      # 数字: 青色(接近 Nord8), 优雅清冷
      numbers = "0;36";
      # 字符串: 黄色, 醒目温暖
      strings = "0;33";
      # 数组外壳 []: 粗体洋红, 结构清晰突出
      arrays = "1;35";
      # 对象外壳 {}: 粗体白色, 结构清晰突出
      objects = "1;37";
      # 对象键名: 粗体蓝色(接近 Nord9/10)
      objectKeys = "1;34";
    };
  };
  # ── jqp: jq 交互式 TUI (可选配套) ──
  programs.jqp = {
    enable = true;
    package = pkgs.jqp;
    settings = {
      # 主题配置
      theme = {
        # Nord 主题(暗色, 与系统配色一致)
        name = "nord";
        # ── 语法高亮颜色覆盖 ──
        # chroma Token 短名参考:
        #   https://github.com/alecthomas/chroma/blob/master/types.go#L210-L308
        # JSON 词法规则参考:
        #   https://github.com/alecthomas/chroma/blob/master/lexers/embedded/json.xml
        chromaStyleOverrides = {
          # 键名: Nord9 蓝 + 下划线
          kc = "#81a1c1 underline";
          # 字符串值: Nord 绿
          str = "#a3be8c";
          # 数字: Nord8 青
          num = "#88c0d0";
          # true/false/null: Nord 紫
          nl = "#b48ead";
        };
        # ── UI 非语法元素颜色覆盖 ──
        # 五个固定字段, 对应 jqp 界面的不同区域文字色
        styleOverrides = {
          # 主文字色: Nord4 浅灰
          primary = "#d8dee9";
          # 次要文字(状态栏等): Nord3 中灰
          secondary = "#4c566a";
          # 错误/警告文字: Nord 红
          error = "#bf616a";
          # 非活跃区域文字: Nord1 深灰
          inactive = "#3b4252";
          # 成功/运行完成文字: Nord 绿
          success = "#a3be8c";
        };
      };
    };
  };
}
