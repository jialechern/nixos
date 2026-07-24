{ config, pkgs, lib, ... }:

{
  programs.rofi = {
    enable = true;

    # --- --- --- 基础配置 --- --- ---
    font = "JetBrainsMono Nerd Font 18";
    location = "center";
    terminal = "${pkgs.ghostty}/bin/ghostty";

    extraConfig = {
      modi = "drun,window,run";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = "📦 ";
      display-window = "🪟 ";
      display-run = "🚀 ";
      drun-display-format = "{name}";
      window-format = "{w}  {c}  —  {t}";
      sort = true;
      sorting-method = "fzf";
      matching = "fuzzy";
      case-sensitive = false;
    };

    # --- --- --- Catppuccin Mocha 调色盘主题 --- --- ---
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      # 全局默认
      "*" = {
        background-color = mkLiteral "#1e1e2e";
        foreground-color = mkLiteral "#cdd6f4";
        border-color = mkLiteral "#45475a";
      };

      # 主窗口
      "window" = {
        width = mkLiteral "50%";
        border = mkLiteral "2px";
        border-radius = mkLiteral "8px";
        border-color = mkLiteral "#45475a";
        background-color = mkLiteral "#1e1e2ed9";
      };

      # 提示符
      "prompt" = {
        text-color = mkLiteral "#89b4fa";
      };

      # 输入框
      "entry" = {
        text-color = mkLiteral "#cdd6f4";
        cursor-color = mkLiteral "#89b4fa";
      };

      # 列表视图
      "listview" = {
        lines = 10;
        dynamic = false;
        fixed-height = true;
        scrollbar = true;
        spacing = mkLiteral "0px";
        background-color = mkLiteral "transparent";
      };

      # 列表项图标
      "element-icon" = {
        size = mkLiteral "1.5em";
      };

      # 列表项 — 默认状态
      "element" = {
        children = mkLiteral "[ element-icon, element-text ]";
        padding = mkLiteral "6px 24px";
        spacing = mkLiteral "12px";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "#cdd6f4";
        border-radius = mkLiteral "0px";
      };

      # 列表项 — 选中状态
      "element selected" = {
        background-color = mkLiteral "#313244";
        text-color = mkLiteral "#cdd6f4";
        border-radius = mkLiteral "4px";
      };

      # 列表项文本 — 匹配高亮
      "element-text" = {
        highlight = mkLiteral "bold #cba6f7";
        text-color = mkLiteral "inherit";
      };

      # 列表项选中文本 — 匹配高亮
      "element selected element-text" = {
        highlight = mkLiteral "bold #94e2d5";
      };

      # 滚动条
      "scrollbar" = {
        handle-width = mkLiteral "4px";
        handle-color = mkLiteral "#6c7086";
        background-color = mkLiteral "transparent";
        border-color = mkLiteral "transparent";
      };

      # 行数计数器
      "num-rows" = {
        text-color = mkLiteral "#a6e3a1";
      };

      # 已过滤行数
      "num-filtered-rows" = {
        text-color = mkLiteral "#a6e3a1";
      };

      # 模式切换按钮
      "button" = {
        text-color = mkLiteral "#cdd6f4";
        background-color = mkLiteral "transparent";
      };

      "button selected" = {
        text-color = mkLiteral "#fab387";
        background-color = mkLiteral "transparent";
      };
    };
  };
}
