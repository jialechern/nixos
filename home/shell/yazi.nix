{ config, pkgs, lib, ... }:

{
  # --- 依赖程序 ---
  home.packages = with pkgs; [
    # file: 让 yazi 稳定地获取 mime 信息
    file
  ];

  # --- yazi 主配置 ---
  programs.yazi = {
    enable = true; # 启用 yazi
    shellWrapperName = "y"; # 生成一个 y 命令作为快捷包装器
    enableFishIntegration = true; # Fish shell 集成
    enableZshIntegration = true; # Zsh shell 集成
    enableBashIntegration = true; # Bash shell 集成

    # --- 插件安装 ---
    # 这里是把插件链接到 ~/.config/yazi/plugins/<name>.yazi
    plugins = {
      git = pkgs.yaziPlugins.git; # Git 状态显示
      "full-border" = pkgs.yaziPlugins."full-border"; # 全边框
      "no-status" = pkgs.yaziPlugins."no-status"; # 去掉状态栏
      "smart-enter" = pkgs.yaziPlugins."smart-enter"; # 一键进入目录/打开文件
      "jump-to-char" = pkgs.yaziPlugins."jump-to-char"; # 类 Vim 的 f<char>
      "toggle-pane" = pkgs.yaziPlugins."toggle-pane"; # 切换面板显示/隐藏/最大化
      "smart-filter" = pkgs.yaziPlugins."smart-filter"; # 更智能的过滤
      chmod = pkgs.yaziPlugins.chmod; # 修改权限
      diff = pkgs.yaziPlugins.diff; # 比较文件差异
      mount = pkgs.yaziPlugins.mount; # 挂载管理
    };

    # --- 主题包 ---
    flavors = {
      nord = pkgs.yaziPlugins.nord; # Nord 主题
    };

    # --- yazi.toml ---
    settings = {
      mgr = {
        ratio = [ 1 4 3 ]; # 左/中/右三个面板宽度比例
        sort_by = "alphabetical"; # 按字母排序
        sort_sensitive = false; # 排序时不区分大小写
        sort_reverse = false; # 不反向排序
        sort_dir_first = true; # 目录优先
        sort_translit = false; # 不做转写排序

        # 这里只保留纯文件列表，不显示额外权限信息
        linemode = "none";

        show_hidden = false; # 默认不显示隐藏文件
        show_symlink = true; # 显示符号链接
        scrolloff = 5; # 光标上下保留 5 行缓冲
      };

      input = {
        cursor_blink = false; # 输入框光标不闪烁

        # cd 输入框
        cd_title = "Change directory:";
        cd_origin = "top-center";
        cd_offset = [ 0 2 50 3 ];

        # 新建文件/目录输入框
        create_title = [ "Create:" "Create (dir):" ];
        create_origin = "top-center";
        create_offset = [ 0 2 50 3 ];

        # 重命名输入框
        rename_title = "Rename:";
        rename_origin = "hovered";
        rename_offset = [ 0 1 50 3 ];
      };

      confirm = {
        trash_title = "Trash {n} selected file{s}?"; # 删除确认标题
        trash_origin = "center"; # 居中显示确认框
        trash_offset = [ 0 0 70 20 ]; # 确认框尺寸/偏移
      };

      plugin = {
        # git.yazi 的 fetcher：让 Yazi 在目录里收集 git 状态
        prepend_fetchers = [
          { url = "*"; run = "git"; group = "git"; } # 普通文件
          { url = "*/"; run = "git"; group = "git"; } # 目录
        ];
      };

      # --- 打开器 ---
      opener = {
        edit = [
          { run = "nvim %s"; block = true; desc = "Neovim"; "for" = "unix"; }
        ];

        image = [
          { run = "loupe %s"; orphan = true; desc = "Loupe"; "for" = "unix"; }
        ];

        ebook = [
          { run = "zathura %s"; orphan = true; desc = "Zathura"; "for" = "unix"; }
        ];

        media = [
          { run = "mpv %s"; orphan = true; desc = "MPV"; "for" = "unix"; }
        ];

        open = [
          { run = "xdg-open %s"; orphan = true; desc = "Open"; "for" = "unix"; }
        ];
      };

      open = {
        # 这里用 prepend_rules, 让规则优先于默认规则
        prepend_rules = [
          # --- 文本文件: 交给 neovim ---
          { mime = "text/*"; use = "edit"; }

          # --- 图片: 交给 loupe ---
          { mime = "image/*"; use = "image"; }

          # --- 音频: 交给 mpv ---
          { mime = "audio/*"; use = "media"; }

          # --- 视频: 交给 mpv ---
          { mime = "video/*"; use = "media"; }

          # --- 兜底: 有些文件 mime 识别不理想时, 按扩展名再补一层 ---
          { url = "*.mp3"; use = "media"; }
          { url = "*.flac"; use = "media"; }
          { url = "*.wav"; use = "media"; }
          { url = "*.aac"; use = "media"; }
          { url = "*.ogg"; use = "media"; }
          { url = "*.m4a"; use = "media"; }
          { url = "*.mp4"; use = "media"; }
          { url = "*.mkv"; use = "media"; }
          { url = "*.mov"; use = "media"; }
          { url = "*.webm"; use = "media"; }

          # --- 电子书: 交给 Zathura ---
          { url = "*.pdf"; use = "ebook"; }
          { url = "*.epub"; use = "ebook"; }
          { url = "*.mobi"; use = "ebook"; }
          { url = "*.djvu"; use = "ebook"; }
        ];
      };
    };

    # --- init.lua ---
    initLua = ''
      			-- =========================================================
      			-- full-border: 给 yazi 加完整边框
      			-- =========================================================
      			require("full-border"):setup()

      			-- =========================================================
      			-- no-status: 去掉底部状态栏，让界面更清爽
      			-- =========================================================
      			require("no-status"):setup()

      			-- =========================================================
      			-- git 插件: 显示 Git 状态标记
      			-- 注意: 符号/样式必须写在 setup() 之前
      			-- =========================================================
      			th.git = th.git or {}

      			-- 未知状态
      			th.git.unknown_sign = " "

      			-- 被 git 忽略的文件
      			th.git.ignored_sign = "∅"

      			-- 未跟踪文件
      			th.git.untracked_sign = "?"

      			-- 已修改
      			th.git.modified_sign = "●"

      			-- 已添加到暂存区
      			th.git.added_sign = "+"

      			-- 已删除
      			th.git.deleted_sign = "×"

      			-- 已更新
      			th.git.updated_sign = "↻"

      			-- 干净文件
      			th.git.clean_sign = "✓"

      			-- Git 状态的颜色样式
      			th.git.unknown	= ui.Style()
      			th.git.ignored	= ui.Style():fg("gray")
      			th.git.untracked = ui.Style():fg("yellow")
      			th.git.modified = ui.Style():fg("blue")
      			th.git.added	= ui.Style():fg("green")
      			th.git.deleted	= ui.Style():fg("red"):bold()
      			th.git.updated	= ui.Style():fg("magenta")
      			th.git.clean	= ui.Style():fg("green")

      			-- 启用 git 插件
      			require("git"):setup({
      				-- 状态标识在 linemode 中的排序权重
      				order = 1500,
      			})

      			-- =========================================================
      			-- smart-enter: 一键"进入目录 / 打开文件"
      			-- 默认只作用于当前悬停项, 更不容易误触
      			-- =========================================================
      			require("smart-enter"):setup({
      				open_multi = false,
      			})
      		'';

    # --- 快捷键 ---
    keymap = {
      mgr.prepend_keymap = [
        { on = [ "q" ]; run = "quit"; desc = "退出程序"; }
        { on = [ "<C-q>" ]; run = "quit"; desc = "退出程序"; }
        { on = [ "Q" ]; run = "quit --no-cwd-file"; desc = "退出但不写 cwd 文件"; }
        { on = [ "<C-c>" ]; run = "close"; desc = "关闭当前标签页"; }
        { on = [ "<C-z>" ]; run = "suspend"; desc = "挂起程序"; }

        # j/k 导航
        { on = [ "k" ]; run = "arrow prev"; desc = "上一项"; }
        { on = [ "j" ]; run = "arrow next"; desc = "下一项"; }
        { on = [ "K" ]; run = "arrow -50%"; desc = "上翻半页"; }
        { on = [ "J" ]; run = "arrow 50%"; desc = "下翻半页"; }

        # -----------------------------------------------------
        # smart-enter: 一键进入目录或打开文件
        # -----------------------------------------------------
        { on = [ "l" ]; run = "plugin smart-enter"; desc = "进入目录或打开文件"; }

        # -----------------------------------------------------
        # jump-to-char: 类似 vim/neovim 的 f<char>
        # -----------------------------------------------------
        { on = [ "f" ]; run = "plugin jump-to-char"; desc = "跳转到首字母匹配项"; }

        # -----------------------------------------------------
        # smart-filter: 更智能的过滤
        # -----------------------------------------------------
        { on = [ "F" ]; run = "plugin smart-filter"; desc = "智能过滤"; }

        # -----------------------------------------------------
        # toggle-pane: 切换预览面板显示/隐藏
        # 这里是常用入口
        # -----------------------------------------------------
        { on = [ "T" ]; run = "plugin toggle-pane min-preview"; desc = "显示或隐藏预览面板"; }

        # -----------------------------------------------------
        # diff: 比较当前选中项和悬停项
        # -----------------------------------------------------
        { on = [ "<C-d>" ]; run = "plugin diff"; desc = "比较选中项与悬停项"; }

        # -----------------------------------------------------
        # mount: 挂载管理
        # -----------------------------------------------------
        { on = [ "M" ]; run = "plugin mount"; desc = "挂载管理"; }

        # -----------------------------------------------------
        # chmod: 修改权限
        # 这里用 c + m 作为两段式按键
        # -----------------------------------------------------
        { on = [ "c" "m" ]; run = "plugin chmod"; desc = "修改文件权限"; }
      ];

      cmp.prepend_keymap = [
        { on = [ "<C-c>" ]; run = "close"; desc = "取消补全"; }
        { on = [ "<A-k>" ]; run = "arrow prev"; desc = "上一项"; }
        { on = [ "<A-j>" ]; run = "arrow next"; desc = "下一项"; }
      ];
    };

    # --- 主题 ---
    theme = {
      flavor = {
        dark = "nord"; # 深色模式使用 nord
        light = "nord"; # 浅色模式也使用 nord
      };

      mgr = {
        cwd = { fg = "cyan"; };
        find_keyword = { fg = "yellow"; bold = true; italic = true; underline = true; };
        find_position = { fg = "magenta"; bg = "reset"; bold = true; italic = true; };
        marker_copied = { fg = "lightgreen"; bg = "lightgreen"; };
        marker_cut = { fg = "lightred"; bg = "lightred"; };
      };
    };
  };
}
