{ config, pkgs, ... }:

{
	programs.bat = {
		enable = true;
		
		# --- --- --- 核心配置 (config) --- --- ---
		config = {
			# --- 主题与视觉 ---
			theme = "Monokai Extended"; # 保持你原有的 Monokai Extended 主题
			italic-text = "always";     # 始终开启斜体（在 Ghostty/Alacritty 中效果极佳）
			color = "always";           # 始终开启颜色
			
			# --- 装饰风格 ---
			# 显示行号、Git 修改标记、页眉，但不显示网格线
			style = "numbers,changes,header"; 
			
			# --- 分页器 (Pager) 设置 ---
			# 确保在 Tmux 下支持鼠标滚动
			pager = "less --RAW-CONTROL-CHARS --quit-if-one-screen --mouse";

			# 自动发现: 当在交互式终端运行时自动开启分页, 管道输出时自动关闭
			paging = "auto";

			# 环绕模式: 长行自动折回, 不截断内容
			wrap = "never"; 

			# 标签缩进: 将 Tab 设置为 4 个空格
			tabs = "4";
		};

		# --- --- --- 语法映射 --- --- ---
		# 这里处理原本通过 --map-syntax 定义的所有逻辑
		# Nix 的写法是 "模式" = [ "目标语言" ];
		extraPackages = with pkgs.bat-extras; [
			batgrep
			batdiff
			batman # 用 bat 来查看 man 手册, 带高亮和搜索
		];
	};

	# 由于 bat 的语法映射在 Home Manager 的 DSL 中通常是通过 `config` 传递参数最直接,
	# 所以在 config 中补全直接所有的 --map-syntax：
	programs.bat.config = {
		"map-syntax" = [
			"*.c:C"
			"*.h:C"
			"*.ino:C++"
			"*.cpp:C++"
			".ignore:Git Ignore"
			"*.rs:Rust"
			"*.py:Python"
			"*.ipy:Python"
			"*.conf:TOML"
			"*.ini:TOML"
			"*.toml:TOML"
			"*.json:JSON"
			"*.java:Java"
			"*.js:JavaScript"
			"*.ts:TypeScript"
			"*.md:Markdown"
			"*.html:HTML"
		];
	};

	# 全局 Shell 别名设置
	home.shellAliases = {
		# 用 bat 替代传统的 cat
		cat = "bat";
		
		# 使用 batgrep 替代 grep, 直接在搜索结果中看到带高亮的代码
		bgrep = "batgrep";
		
		# 使用 batdiff 替代 git diff, 查看更漂亮的代码变动
		bdiff = "batdiff";
		
		# 安装了 batman, 可以用 alias 覆盖传统的 man
		# 这样以后输入 man <命令> 就会默认使用带高亮的 bat 渲染
		man = "batman";
	};
}
