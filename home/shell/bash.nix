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
            ff = "fastfetch";
			lg = "lazygit";
			rsync = "rsync -arvP";
            px = "proxychains4 -f ~/.config/proxychains/proxychains.conf -q";
		};

		# --- --- --- 自定义函数 --- --- ---
		bashrcExtra = ''
		'';
	};

	# --- --- --- PATH 路径管理 --- --- ---
	home.sessionPath = [
		"$HOME/.local/bin"
		"$HOME/Projects/bin"
		"$HOME/.cargo/bin"
	];
}
