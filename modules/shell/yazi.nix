{ config, pkgs, ... }:

{
    # --- --- --- 依赖程序安装 --- --- ---
    home.packages = with pkgs.yaziPlugins; [
        git
    ];

    # --- --- --- yazi 配置 --- --- ---
	programs.yazi = {
		enable = true;
        shellWrapperName = "y";
		enableFishIntegration = true;
		enableZshIntegration = true;
		enableBashIntegration = true;

        # --- --- --- 插件配置 --- --- ---
        plugins = with pkgs.yaziPlugins; {
            git = git;
        };

        # --- --- --- 基本配置 --- --- ---
		settings = {
			mgr = {
				# 三个面板的宽高比
				ratio = [ 1 4 3 ];
				# 排序方式
				sort_by = "alphabetical";
				sort_sensitive = false;
				sort_reverse = false;
				sort_dir_first = true;
				sort_translit = false;
				linemode = "none";
				show_hidden = false;
				show_symlink = true;
				scrolloff = 5;
			};

			input = {
				cursor_blink = false;
				# cd
				cd_title = "Change directory:";
				cd_origin = "top-center";
				cd_offset = [ 0 2 50 3 ];
				# create
				create_title = [ "Create:" "Create (dir):" ];
				create_origin = "top-center";
				create_offset = [ 0 2 50 3 ];
				# rename
				rename_title = "Rename:";
				rename_origin = "hovered";
				rename_offset = [ 0 1 50 3 ];
			};

			confirm = {
				trash_title = "Trash {n} selected file{s}?";
				trash_origin = "center";
				trash_offset = [ 0 0 70 20 ];
			};

            plugin = {
                prepend_fetchers = [
                    { id = "git"; name = "*"; run = "git"; }
                    { id = "git"; name = "*/"; run = "git"; }
                ];
            };
		};

        # --- --- --- 按键映射 --- --- ---
		keymap = {
			mgr.prepend_keymap = [
				{ on = [ "q" ]; run = "quit"; desc = "Quit the process"; }
				{ on = [ "<C-q>" ]; run = "quit"; desc = "Quit the process"; }
				{ on = [ "Q" ]; run = "quit --no-cwd-file"; desc = "Quit without outputting cwd-file"; }
				{ on = [ "<C-c>" ]; run = "close"; desc = "Close the current tab, or quit if it's last"; }
				{ on = [ "<C-z>" ]; run = "suspend"; desc = "Suspend the process"; }

				# Hopping
				{ on = [ "k" ]; run = "arrow prev"; desc = "Previous file"; }
				{ on = [ "j" ]; run = "arrow next"; desc = "Next file"; }
				{ on = [ "K" ]; run = "arrow -50%"; desc = "Move cursor up half page"; }
				{ on = [ "J" ]; run = "arrow 50%"; desc = "Move cursor down half page"; }
			];

			cmp.prepend_keymap = [
				{ on = [ "<C-c>" ]; run = "close"; desc = "Cancel completion"; }
				{ on = [ "<A-k>" ]; run = "arrow prev"; desc = "Previous item"; }
				{ on = [ "<A-j>" ]; run = "arrow next"; desc = "Next item"; }
			];
		};

        # --- --- --- 主题配置 --- --- ---
		theme = {
			flavor = {
				dark = "nord";
				light = "nord";
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

    # 引入 nord 主题的插件
    xdg.configFile."yazi/flavors/nord.yazi".source = pkgs.yaziPlugins.nord;
    # 应用插件
    xdg.configFile."yazi/init.lua".text = ''
        require("git"):setup({ order = 1500, })
    '';
}
