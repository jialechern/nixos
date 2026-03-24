{ config, pkgs, lib, ... }:

{
	home.packages = [ pkgs.swww ];

	systemd.user.services.swww = {
		Unit = {
			Description = "swww wallpaper daemon";
			After = [ "graphical-session-pre.target" ];
			PartOf = [ "graphical-session.target" ];
		};

		Service = {
			Type = "simple";

			# 启动守护进程
			ExecStart = "${pkgs.swww}/bin/swww-daemon";
			
			Restart = "on-failure";
			RestartSec = 1;
		};

		Install = {
			WantedBy = [ "graphical-session.target" ];
		};
	};
}
