{ config, pkgs, lib, ... }:

let
  # 所有内置语言（按字母顺序，便于查找）
  availableLanguages = [
    "c" "csharp" "english100" "english200" "english1000"
    "english-advanced" "english-pirate" "french100" "french200"
    "french1000" "german" "german1000" "german10000" "go" "html"
    "java" "javascript" "norwegian" "php" "portuguese"
    "portuguese1000" "portuguese200" "portuguese-advanced"
    "python" "qt" "ruby" "rust" "russian" "russian1000"
    "russian10000" "spanish" "sql" "thai" "ukrainian"
  ];

  # 可用的 ANSI 颜色名称
  availableColors = [
    "black" "white" "red" "green" "yellow" "blue"
    "magenta" "cyan" "gray" "darkgray" "lightred" "lightgreen"
    "lightyellow" "lightblue" "lightmagenta" "lightcyan"
    "none" "reset"
  ];

  # 可用的样式修饰符
  availableModifiers = [
    "bold" "crossed_out" "dim" "hidden" "italic"
    "rapid_blink" "slow_blink" "reversed" "underlined"
  ];

  # 可用的边框类型
  availableBorderTypes = [
    "plain" "rounded" "double" "thick"
    "quadrantinside" "quadrantoutside"
  ];
in
{
  # --- --- --- programs.ttyper --- --- ---
  # ttyper: 终端打字测试工具（Rust + Ratatui 实现）
  # 仓库: https://github.com/max-niederman/ttyper
  # Home Manager 模块: module nixos/ttyper
  #
  # 样式语法: "前景色:背景色;修饰符;修饰符"
  #   - 颜色: 命名颜色（${lib.concatStringsSep ", " availableColors}）或 6 位 hex
  #   - 修饰符: ${lib.concatStringsSep ", " availableModifiers}
  programs.ttyper = {
    enable = true;

    settings = {
      # --- --- --- 默认语言 --- --- ---
      # 不通过 -l 手动指定语言时的默认语言
      # 可选值: ${lib.concatStringsSep ", " availableLanguages}
      # 额外语言可通过在 ~/.config/ttyper/language/ 下创建每行一个单词的文本文件添加
      default_language = "english200";

      # --- --- --- 主题 [theme] --- --- ---
      theme = {
        # ===================== 全局默认 =====================
        # 全局默认样式（包括空白单元格的背景样式）
        default = "none";

        # ===================== 标题 =====================
        # 界面上方 "ttyper" 标题的样式
        title = "white;bold";

        # ===================== 测试界面 =====================

        # --- 边框 ---
        # 所有边框的绘制风格
        # 可选: ${lib.concatStringsSep "|" availableBorderTypes}
        border_type = "rounded";

        # 输入框（你正在键入的区域）的边框颜色
        input_border = "cyan";

        # 提示词区域（待键入的单词列表）的边框颜色
        prompt_border = "green";

        # --- 已完成单词样式 ---
        # 已正确键入完成的单词
        prompt_correct = "green";

        # 已键入但包含错误的单词
        prompt_incorrect = "red";

        # 尚未键入的单词
        prompt_untyped = "gray";

        # --- 当前单词逐字母样式 ---
        # 当前单词中已正确键入的字母
        prompt_current_correct = "green;bold";

        # 当前单词中键入错误的字母
        prompt_current_incorrect = "red;bold";

        # 当前单词中尚未键入的字母
        prompt_current_untyped = "blue;bold";

        # --- 光标 ---
        # 当前光标位置所用字符（默认为下划线）的样式
        prompt_cursor = "none;underlined";

        # ===================== 结果界面 =====================

        # --- 概览区域 ---
        # 概览文字（WPM、正确率、用时等统计数据）
        results_overview = "cyan;bold";

        # 概览区域的边框颜色
        results_overview_border = "cyan";

        # --- 最差按键 ---
        # "最差按键"区域的表头文字
        results_worst_keys = "cyan;bold";

        # "最差按键"区域的边框颜色
        results_worst_keys_border = "cyan";

        # --- WPM 图表 ---
        # 图表中数据点/线条的颜色
        results_chart = "cyan";

        # 图表 X 轴（时间）标签的样式
        results_chart_x = "cyan";

        # 图表 Y 轴（WPM）标签的样式
        results_chart_y = "gray;bold";

        # --- 底部提示 ---
        # 结果界面底部 "按 r 重新开始 / 按 q 退出" 提示的样式
        results_restart_prompt = "gray;italic";
      };
    };
  };

  # --- --- --- Shell 别名 --- --- ---
  # ttyper 常用 CLI 参数组合的快速别名
  #
  # CLI 参数速查:
  #   -l, --language <lang>       指定语言（可选值同上）
  #   -w, --words <n>             每次测试的单词/行数（默认 50）
  #   --no-backtrack              禁止回溯到已完成单词
  #   --sudden-death              首次错误即重新开始
  #   --no-backspace              禁用退格键
  #   --list-languages            列出所有已安装的语言
  #   --language-file <file>      从文件加载语言词库
  #   -c, --config <file>         使用指定的配置文件
  #   <contents>                  从文本文件逐行读取测试内容
}
