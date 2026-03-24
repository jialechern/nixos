{ config, pkgs, lib, ... }:

{
    # --- --- --- 安装必要程序 --- --- ---
    home.packages = [
        # ble.sh 插件
        pkgs.blesh
    ];

	programs.bash = {
		enable = true;
		# 启用自动补全
		enableCompletion = true;

		# --- --- --- 插件 --- --- ---
		initExtra = ''
            # 开启高亮与自动补全
            source ${pkgs.blesh}/share/blesh/ble.sh
		'';

		# --- --- --- 环境变量 --- --- ---
		sessionVariables = {
            # --- 编辑器 ---
            EDITOR = "nvim";

            # --- ollama 配置 ---
            OLLAMA_MODELS = "$HOME/LLMS";

            # 启用 GPU
            OLLAMA_FORCE_GPU = "1";

            # --- rust 设置 ---
			RUST_BACKTRACE = "1";
			RUSTUP_DIST_SERVER = "https://rsproxy.cn";
			RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
		};

		# --- --- --- 别名设置 --- --- ---
		shellAliases = {
			lg = "lazygit";
			rsync = "rsync -arvP";
            update-grub = "sudo grub-mkconfig -o /boot/grub/grub.cfg";
			proxychains = "proxychains -q";
			archwiki = "firefox $(fd '.*' --full-path /usr/share/doc/arch-wiki-zh-cn/html/zh-cn/ | fzf)";
		};

		# --- --- --- 自定义函数 --- --- ---
		bashrcExtra = ''
			# NPM 全局环境初始化 [cite: 30]
			if [ ! -d "$HOME/.local/share/npm-global" ]; then
				mkdir -p "$HOME/.local/share/npm-global"
			fi
		'';
	};

	# --- --- --- PATH 路径管理 --- --- ---
	home.sessionPath = [
		"$HOME/.local/bin"
		"$HOME/Projects/bin"
		"$HOME/.cargo/bin"
	];
}
