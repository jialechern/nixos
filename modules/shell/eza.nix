{ config, pkgs, ... }:

{
    programs.eza = {
    	enable = true;

        # 显示颜色
        colors = "always";

    	# 自动将 ls/ll/la/lt 等命令重定向到 eza
    	enableZshIntegration = true; 
    	enableBashIntegration = true;
    	enableFishIntegration = true;
    	
    	# 常用配置项
    	git = true;                     # 显示文件的 Git 状态
    	icons = "always";                 # 自动显示图标 (需要终端支持 Nerd Fonts)
    	extraOptions = [
    		"--group-directories-first" # 目录排在文件前面
    		"--header"                  # 显示列标题
    		"--octal-permissions"       # 显示八进制权限位
    	];
    };
}
