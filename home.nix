{ config, pkgs, inputs, username, ... }:

{
    # Home Manager 需要一些关于它应该管理的路径的信息
	home.username = "${username}";
	home.homeDirectory = "/home/${username}";

    # 此值决定了您的配置与哪个 Home Manager 版本兼容
    # 这有助于避免当新的 Home Manager 版本引入向后不兼容的更改时出现破坏
    #
    # 即使您更新了 Home Manager，也不应更改此值。如果您确实
    # 想要更新此值, 请务必先查看 Home Manager 的发布说明
	home.stateVersion = "25.11"; # 请在更改前阅读注释

	# 让 Home Manager 安装和管理自身
	programs.home-manager.enable = true;

    # --- --- --- 引入配置 --- --- ---
    imports = [

        # 基本的 Shell 配置
        ./home/shell.nix

        # 开发环境
        ./home/dev.nix

        # 其它程序配置
        ./home/other.nix

    ] ++ (builtins.filter builtins.pathExists [

        # neovim 配置
        ./home/nvim.nix

        # niri 配置
        ./home/niri.nix

        # 桌面环境配置
        ./home/desktop.nix

        ]);

    # --- --- --- 生成标准家目录 --- --- ---
    # 开启 XDG 用户目录管理
    xdg.userDirs = {
      enable = true;
      # 核心选项: 构建时如果不存在则自动创建
      createDirectories = true;
      setSessionVariables = true;
      
      # 定义具体的文件夹路径
      # 使用 "${config.home.homeDirectory}" 确保路径指向家目录
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      music = "${config.home.homeDirectory}/Music";
      desktop = "${config.home.homeDirectory}/Desktop";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
  
      # 定义额外的自定义目录
      extraConfig = {
        WALLPAPERS = "${config.home.homeDirectory}/Pictures/WallPapers";
        PROJECTS = "${config.home.homeDirectory}/Projects";
        TEST = "${config.home.homeDirectory}/Test";
        STU = "${config.home.homeDirectory}/Stu";
      };
    };

    # --- --- --- 其它细碎配置 --- --- ---
    # niri 依赖的光标配置
    home.pointerCursor = {
      package = pkgs.kdePackages.breeze;
      name = "breeze_cursors";
      size = 24;
      # 同时开启 GTK 和 X11 光标支持
      gtk.enable = true;
      x11.enable = true;
    };

    # --- 下载即使用的软件 ---
    # home.packages 选项允许您将 Nix 软件包安装到您的环境中
	home.packages = with pkgs; [
        # # 将 'hello' 命令添加到环境中. 运行时它会打印友好的 "Hello, world!"
        #
        # pkgs.hello
        #
        # # 有时微调包很有用, 例如通过应用覆盖
        # # 可以直接在这里进行, 只是别忘了括号. 也可以安装 Nerd Fonts
        #
        # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
        #
        # # 也可以直接在配置中创建简单的 shell 脚本
        # # 例如, 这将向环境添加一个 'my-hello' 命令:
        #
        # (pkgs.writeShellScriptBin "my-hello" ''
        #   echo "Hello, ${config.home.username}!"
        # '')
	];

    # Home Manager 非常擅长管理 dot 文件 (dotfiles). 管理纯文本文件的
    # 主要方式是通过 'home.file'
	home.file = {
        # 是的 fcitx5 主题插件在需要的目录下可见
        ".local/share/fcitx5/themes".source = "${pkgs.fcitx5-nord}/share/fcitx5/themes";

        # # 构建此配置将在 Nix 存储中创建 'dotfiles/screenrc' 的副本
        # # 激活配置后, '~/.screenrc' 将成为指向 Nix 存储副本的符号链接
        # ".screenrc".source = dotfiles/screenrc;
        
        # # 您也可以直接设置文件内容
        # ".gradle/gradle.properties".text = ''
        #   org.gradle.console=verbose
        #   org.gradle.daemon.idletimeout=3600000
        # '';
	};

    # Home Manager 也可以通过 'home.sessionVariables' 管理环境变量
	# 当使用 Home Manager 提供的 shell 时, 这些变量将被显式地加载
	# 如果不想通过 Home Manager 管理 shell, 那么需要手动加载
	# 位于以下位置之一的 'hm-session-vars.sh'：
	#
	#	~/.nix-profile/etc/profile.d/hm-session-vars.sh
	#
	# 或
	#
	#	~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
	#
	# 或
	#
	#	/etc/profiles/per-user/${username}/etc/profile.d/hm-session-vars.sh
	#
	home.sessionVariables = {
		# EDITOR = "nvim";
	};

    # 启用 home-manager 中安装的字体
    fonts.fontconfig.enable = true;
    # 为非 NixOS 系统导出必要的 Linux 环境变量
    # targets.genericLinux.enable = true;
}
