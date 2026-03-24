{ config, pkgs, ... }:

{
	home.packages = with pkgs; [
        # --- 文件管理器及其插件 ---
    	thunar
    	thunar-archive-plugin
    	thunar-volman
    	tumbler           # 缩略图服务
    	ffmpegthumbnailer # 视频缩略图
    	gnome-keyring     # 密码管理
    	gvfs              # 核心挂载服务 (包含 smb 支持)
    	
    	# --- 音视频流媒体 (PipeWire 相关工具) ---
    	pavucontrol # 音量控制面板
    	playerctl   # 媒体控制命令行 (niri 常用)
    	gst_all_1.gst-plugins-base
    	gst_all_1.gst-plugins-good
    	gst_all_1.gst-libav
    	
    	# --- 桌面工具 ---
    	brightnessctl        # 亮度控制
    	wl-clipboard         # 剪贴板基础
        swww                 # 壁纸底层
        waypaper             # 壁纸图形化
    	overskride           # 蓝牙管理
    	loupe                # 图片查看器
    	libnotify            # 通知库
    	polkit_gnome         # 权限认证代理
	firefox
    	
    	# --- 字体、主题与图标 ---
    	nordic                 # GTK 主题
    	papirus-icon-theme     # 图标主题
        noto-fonts-cjk-sans    # 核心中文字体
        noto-fonts-color-emoji # 表情符号支持

        # --- 终端模拟器 ---
	alacritty
	ghostty

        # --- 其它应用程序 ---
        # Telegram 桌面端
        telegram-desktop
        # QQ
        qq
        # 微信
        wechat
        # 开源办公套件
        libreoffice-fresh
        # # 几何画板
        # geogebra
        # GNU 图形处理工具
        gimp
        # p2p 下载器
        qbittorrent
        # Steam
        steam
        # Windows prefix 管理器
        bottles
        # 我的世界启动器
        prismlauncher
        # # 桌面共享工具
        # rustdesk
    ];
}
