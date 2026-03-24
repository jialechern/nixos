{ config, pkgs, lib, ... }:

{
	programs.fish = {
		enable = true;

		# --- --- --- 启动与全局变量设置 --- --- ---
		interactiveShellInit = ''
			# 取消启动欢迎信息
			set -g fish_greeting ""
			
			# 模式提示符颜色与符号
			function fish_mode_prompt
				switch $fish_bind_mode
					case default
						set_color --bold red
						echo "[N]"
					case insert
						set_color --bold green
						echo "[I]"
					case replace_one
						set_color --bold yellow
						echo "[R]"
				end
				set_color normal
			end

			# 设置光标形状
			set -gx fish_cursor block
			set -gx fish_vi_cursor default block
			set -gx fish_vi_cursor insert block
			set -gx fish_vi_cursor visual underscore
		'';

		# --- --- --- 插件 --- --- ---
		plugins = [
			{ name = "done"; src = pkgs.fishPlugins.done.src; }
			{ name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
			{ name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
		];
		
		# --- --- --- 别名设置 --- --- ---
        # 即时展开的命令
		shellAbbrs = {};
        # 别名
		shellAliases = {
            lg = "lazygit";
            rsync = "rsync -arvP";
            proxychains = "proxychains -q";
            update-grub = "sudo grub-mkconfig -o /boot/grub/grub.cfg";
            archwiki = "firefox $(fd \".*\" --full-path /usr/share/doc/arch-wiki-zh-cn/html/zh-cn/ | fzf)";
		};

		# --- --- --- 自定义函数 --- --- ---
		functions = {};
	};

	# --- --- --- 环境变量与 Path --- --- ---
	home.sessionVariables = {
        # --- 编辑器 ---
        EDITOR = "nvim";
        # --- tldr 配置 ---
        TLDR_LANG = "zh";
        # --- ollama 配置 ---
        OLLAMA_MODELS = "$HOME/LLMS";
        # 启用 GPU
        OLLAMA_FORCE_GPU = "1";

        # --- Rust 配置 ---
        # 打印详细 BACKTRACE
        RUST_BACKTRACE = "1";
        # Rust 代理设置
        RUSTUP_DIST_SERVER = "https://rsproxy.cn";
        RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
	};

	home.sessionPath = [
		"$HOME/.local/bin"
		"$HOME/.local/share/npm-global/bin"
		"$HOME/Projects/bin"
		"$HOME/.cargo/bin"
	];

}
