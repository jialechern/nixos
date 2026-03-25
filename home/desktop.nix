{ config, pkgs, ... }:

{
	imports = [
        ./desktop/gtk.nix
        ./desktop/qt.nix
        ./desktop/xdg-desktop-portal.nix
        ./desktop/default-application.nix
        ./desktop/fcitx5.nix
        ./desktop/fuzzel.nix
        ./desktop/swaylock.nix
        ./desktop/mpv.nix
        ./desktop/zathura.nix
	    ./desktop/keepassxc.nix
        ./desktop/applications.nix
        # ghostty 配置
        (if builtins.pathExists ./ghostty.nix then ./ghostty.nix else {})
        # alacritty 配置
        (if builtins.pathExists ./alacritty.nix then ./alacritty.nix else {})


        # services
        ./desktop/services/wl-clip-persist.nix
        ./desktop/services/mako.nix
        ./desktop/services/polkit-gnome-authentication-agent-1.nix
        ./desktop/services/waybar.nix
        ./desktop/services/swayidle.nix
        ./desktop/services/wlsunset.nix
        ./desktop/services/swww.nix
	];

	# --- --- --- 环境变量与会话同步 --- --- ---
	home.sessionVariables = {
        # 设置桌面环境为 niri
		XDG_CURRENT_DESKTOP = "niri";

		# 强制部分 GTK 应用使用 Wayland
		GDK_BACKEND = "wayland,x11";

        # Wayland 环境中运行 Electron 应用必要的环境变量
        ELECTRON_OZONE_PLATFORM_HINT =  "auto";
        ELECTRON_ENABLE_FEATURES = "WaylandWindowDecorations";
        
        # Qt 主题设置
        QT_QPA_PLATFORMTHEME = "qt6ct";
	};
}
