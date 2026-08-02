{ config, pkgs, lib, ... }:

{
  programs.rofi = {
    enable = true;

    # --- --- --- 基础配置 --- --- ---
    font = "JetBrainsMono Nerd Font 16";
    location = "center";
    terminal = "${pkgs.ghostty}/bin/ghostty";

    extraConfig = {
      modi = "drun,run,filebrowser,window";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = "";
      display-run = "";
      display-filebrowser = "";
      display-window = "";
      drun-display-format = "{name}";
      window-format = "{w} · {c} · {t}";
    };

    # --- --- --- Catppuccin Mocha 主题 (基于 adi1090x/rofi type-1/style-5) --- --- ---
    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        # 全局变量定义
        "*" = {
          # Catppuccin Mocha 基础色
          background = mkLiteral "#1e1e2e";
          "background-alt" = mkLiteral "#313244";
          foreground = mkLiteral "#cdd6f4";
          selected = mkLiteral "#cba6f7";
          active = mkLiteral "#a6e3a1";
          urgent = mkLiteral "#f38ba8";

          # 派生变量
          "border-colour" = mkLiteral "var(selected)";
          "handle-colour" = mkLiteral "var(selected)";
          "background-colour" = mkLiteral "var(background)";
          "foreground-colour" = mkLiteral "var(foreground)";
          "alternate-background" = mkLiteral "var(background-alt)";

          # 元素状态色变量
          "normal-background" = mkLiteral "var(background)";
          "normal-foreground" = mkLiteral "var(foreground)";
          "urgent-background" = mkLiteral "var(urgent)";
          "urgent-foreground" = mkLiteral "var(background)";
          "active-background" = mkLiteral "var(active)";
          "active-foreground" = mkLiteral "var(background)";
          "selected-normal-background" = mkLiteral "var(selected)";
          "selected-normal-foreground" = mkLiteral "var(background)";
          "selected-urgent-background" = mkLiteral "var(active)";
          "selected-urgent-foreground" = mkLiteral "var(background)";
          "selected-active-background" = mkLiteral "var(urgent)";
          "selected-active-foreground" = mkLiteral "var(background)";
          "alternate-normal-background" = mkLiteral "var(background)";
          "alternate-normal-foreground" = mkLiteral "var(foreground)";
          "alternate-urgent-background" = mkLiteral "var(urgent)";
          "alternate-urgent-foreground" = mkLiteral "var(background)";
          "alternate-active-background" = mkLiteral "var(active)";
          "alternate-active-foreground" = mkLiteral "var(background)";
        };

        # 主窗口
        "window" = {
          transparency = mkLiteral "\"real\"";
          anchor = mkLiteral "center";
          fullscreen = false;
          width = mkLiteral "600px";
          "x-offset" = mkLiteral "0px";
          "y-offset" = mkLiteral "0px";

          enabled = true;
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "10px";
          "border-color" = mkLiteral "@border-colour";
          cursor = mkLiteral "\"default\"";
          "background-color" = mkLiteral "rgba(30, 30, 46, 0.88)";
        };

        # 主容器
        "mainbox" = {
          enabled = true;
          spacing = mkLiteral "8px";
          margin = mkLiteral "0px";
          padding = mkLiteral "24px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "0px 0px 0px 0px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "transparent";
          children = mkLiteral "[ inputbar, message, listview ]";
        };

        # 输入栏
        "inputbar" = {
          enabled = true;
          spacing = mkLiteral "10px";
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "0px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "@foreground-colour";
          children = mkLiteral "[ textbox-prompt-colon, entry, mode-switcher ]";
        };

        # 搜索图标
        "textbox-prompt-colon" = {
          enabled = true;
          padding = mkLiteral "6px 10px";
          expand = false;
          str = mkLiteral "\"  \"";
          font = mkLiteral "\"JetBrainsMono Nerd Font 15\"";
          "background-color" = mkLiteral "inherit";
          "text-color" = mkLiteral "inherit";
        };

        # 输入框
        "entry" = {
          enabled = true;
          padding = mkLiteral "6px 0px";
          "background-color" = mkLiteral "inherit";
          "text-color" = mkLiteral "inherit";
          cursor = mkLiteral "text";
          placeholder = mkLiteral "\"Search...\"";
          "placeholder-color" = mkLiteral "inherit";
        };

        # 行数计数器
        "num-filtered-rows" = {
          enabled = true;
          expand = false;
          "background-color" = mkLiteral "inherit";
          "text-color" = mkLiteral "inherit";
        };

        "textbox-num-sep" = {
          enabled = true;
          expand = false;
          str = mkLiteral "\"/\"";
          "background-color" = mkLiteral "inherit";
          "text-color" = mkLiteral "inherit";
        };

        "num-rows" = {
          enabled = true;
          expand = false;
          "background-color" = mkLiteral "inherit";
          "text-color" = mkLiteral "inherit";
        };

        "case-indicator" = {
          enabled = true;
          "background-color" = mkLiteral "inherit";
          "text-color" = mkLiteral "inherit";
        };

        # 列表视图
        "listview" = {
          enabled = true;
          columns = 1;
          lines = 8;
          cycle = true;
          dynamic = true;
          scrollbar = true;
          layout = mkLiteral "vertical";
          reverse = false;
          "fixed-height" = true;
          "fixed-columns" = true;

          spacing = mkLiteral "6px";
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "0px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "@foreground-colour";
          cursor = mkLiteral "\"default\"";
        };

        # 滚动条
        "scrollbar" = {
          "handle-width" = mkLiteral "5px";
          "handle-color" = mkLiteral "@handle-colour";
          "border-radius" = mkLiteral "10px";
          "background-color" = mkLiteral "@alternate-background";
        };

        # 元素基础
        "element" = {
          enabled = true;
          spacing = mkLiteral "8px";
          margin = mkLiteral "0px";
          padding = mkLiteral "6px 12px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "10px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "@foreground-colour";
          cursor = mkLiteral "pointer";
        };

        # 元素状态选择器
        "element normal.normal" = {
          "background-color" = mkLiteral "var(normal-background)";
          "text-color" = mkLiteral "var(normal-foreground)";
        };

        "element normal.urgent" = {
          "background-color" = mkLiteral "var(urgent-background)";
          "text-color" = mkLiteral "var(urgent-foreground)";
        };

        "element normal.active" = {
          "background-color" = mkLiteral "var(active-background)";
          "text-color" = mkLiteral "var(active-foreground)";
        };

        "element selected.normal" = {
          "background-color" = mkLiteral "var(selected-normal-background)";
          "text-color" = mkLiteral "var(selected-normal-foreground)";
        };

        "element selected.urgent" = {
          "background-color" = mkLiteral "var(selected-urgent-background)";
          "text-color" = mkLiteral "var(selected-urgent-foreground)";
        };

        "element selected.active" = {
          "background-color" = mkLiteral "var(selected-active-background)";
          "text-color" = mkLiteral "var(selected-active-foreground)";
        };

        "element alternate.normal" = {
          "background-color" = mkLiteral "var(alternate-normal-background)";
          "text-color" = mkLiteral "var(alternate-normal-foreground)";
        };

        "element alternate.urgent" = {
          "background-color" = mkLiteral "var(alternate-urgent-background)";
          "text-color" = mkLiteral "var(alternate-urgent-foreground)";
        };

        "element alternate.active" = {
          "background-color" = mkLiteral "var(alternate-active-background)";
          "text-color" = mkLiteral "var(alternate-active-foreground)";
        };

        # 元素图标
        "element-icon" = {
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "inherit";
          size = mkLiteral "22px";
          cursor = mkLiteral "inherit";
        };

        # 元素文本
        "element-text" = {
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "inherit";
          highlight = mkLiteral "inherit";
          cursor = mkLiteral "inherit";
          "vertical-align" = mkLiteral "0.5";
          "horizontal-align" = mkLiteral "0.0";
        };

        # 模式切换器
        "mode-switcher" = {
          enabled = true;
          expand = true;
          spacing = mkLiteral "8px";
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "0px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "@foreground-colour";
        };

        # 按钮
        "button" = {
          padding = mkLiteral "4px 10px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "10px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "@alternate-background";
          "text-color" = mkLiteral "inherit";
          cursor = mkLiteral "pointer";
        };

        "button selected" = {
          "background-color" = mkLiteral "var(selected-normal-background)";
          "text-color" = mkLiteral "var(selected-normal-foreground)";
        };

        # 消息区域
        "message" = {
          enabled = true;
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "0px 0px 0px 0px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "transparent";
          "text-color" = mkLiteral "@foreground-colour";
        };

        "textbox" = {
          padding = mkLiteral "6px 8px";
          border = mkLiteral "0px solid";
          "border-radius" = mkLiteral "10px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "@alternate-background";
          "text-color" = mkLiteral "@foreground-colour";
          "vertical-align" = mkLiteral "0.5";
          "horizontal-align" = mkLiteral "0.0";
          highlight = mkLiteral "none";
          "placeholder-color" = mkLiteral "@foreground-colour";
          blink = true;
          markup = true;
        };

        "error-message" = {
          padding = mkLiteral "10px";
          border = mkLiteral "2px solid";
          "border-radius" = mkLiteral "10px";
          "border-color" = mkLiteral "@border-colour";
          "background-color" = mkLiteral "@background-colour";
          "text-color" = mkLiteral "@foreground-colour";
        };
      };
  };
}
