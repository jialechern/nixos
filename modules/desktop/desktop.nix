{ config, pkgs, ... }:

{
	imports = [
        ./gtk.nix
        ./qt.nix
        ./xdg-desktop-portal.nix
        ./default-application.nix
        ./fuzzel.nix
        ./swaylock.nix
        ./mpv.nix
        ./zathura.nix
	./keepassxc.nix
        ./applications.nix
        # ghostty 配置
        (if builtins.pathExists ../ghostty.nix then ../ghostty.nix else {})
        # alacritty 配置
        (if builtins.pathExists ../alacritty.nix then ../alacritty.nix else {})


        # services
        ./services/fcitx5.nix
        ./services/mako.nix
        ./services/polkit-gnome-authentication-agent-1.nix
        ./services/waybar.nix
        ./services/swayidle.nix
        ./services/wlsunset.nix
        ./services/wl-clip-persist.nix
        ./services/swww.nix
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
