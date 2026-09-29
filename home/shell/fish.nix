{ pkgs, ... }:

{
  # 注: 通用别名(含 nclean, 因 preferAbbrs 在 fish 下以缩写生效) / PATH 见 ./common.nix
  programs.fish = {
    enable = true;

    # --- 包与补全 ---

    # package 默认为 pkgs.fish, 无需显式声明
    # generateCompletions 默认为 true, 无需显式声明

    # --- 交互式 Shell 初始化(VI 模式、光标、提示符)---
    interactiveShellInit = ''
      # -------- 启用 VI 键绑定 --------
      fish_vi_key_bindings

      # -------- 关闭启动欢迎语 --------
      set -g fish_greeting ""

      # 注意: 不要在这里自绘 fish_mode_prompt —— starship 的 fish 集成会在运行时
      # 执行 `builtin functions -e fish_mode_prompt` 把它删掉 (定义必然失效)。
      # VI 模式指示改用 starship 的 character.vimcmd_symbol / vimcmd_replace_symbol。

      # -------- VI 模式光标形状(仅支持 DECSCUSR 的终端)--------
      # 普通模式     → 方块 (闪烁)
      set -g fish_cursor_default block blink
      # 插入模式     → 竖线 (闪烁)
      set -g fish_cursor_insert line blink
      # 可视模式     → 方块 (闪烁)
      set -g fish_cursor_visual block blink
      # 替换模式     → 下划线 (闪烁)
      set -g fish_cursor_replace_one underscore blink
      set -g fish_cursor_replace underscore blink
      # 外部命令执行时 → 竖线 (闪烁)
      set -g fish_cursor_external line blink
    '';

    # --- 插件 ---
    plugins = [
      # 长时间运行命令结束后发送桌面通知
      { name = "done"; src = pkgs.fishPlugins.done.src; }
      # fzf 模糊搜索集成 (本插件提供 Ctrl+R 历史搜索、Ctrl+Alt+F/L/S 等;
      # Ctrl+T 文件搜索来自 programs.fzf 的原生集成, 不是本插件提供)
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      # 自动补全配对的括号、引号
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
    ];

    # --- 缩写(abbr)---
    # 输入缩写后按空格 / 回车自动展开为完整命令; 展开后仍可编辑
    # 若其他模块也为 fish 定义了别名, 可启用 preferAbbrs 以优先使用缩写
    preferAbbrs = true;
    # fish 专属缩写可加在此; 通用别名由 common.nix 提供 (preferAbbrs 已使其以缩写生效)
    shellAbbrs = { };

    # --- 自定义补全 ---
    # 为不在标准路径中的命令添加补全
    completions = { };
  };

  # ============================================================
  # 可选增强 (按需取消注释启用)
  # ============================================================

  # 1. Atuin 魔法历史: 替换默认 C-r, 全设备同步历史, 支持模糊搜索
  #    programs.atuin = {
  #      enable = true;
  #      enableFishIntegration = true;
  #    };
  #    然后: programs.fzf.historyWidget.command 设为 "" 以避免 C-r 冲突

  # 2. direnv 自动环境加载: 进入目录时自动加载 .envrc
  #    programs.direnv = {
  #      enable = true;
  #      enableFishIntegration = true;
  #      nix-direnv.enable = true;
  #    };
}
