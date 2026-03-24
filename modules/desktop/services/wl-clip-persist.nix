{ config, pkgs, ... }:

{
    # 确保复制内容在程序关闭后不丢失
    systemd.user.services.wl-clip-persist = {
    	Unit = { Description = "Keep clipboard persistence"; After = [ "graphical-session.target" ]; };
    	Service = {
    		ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
    		Restart = "always";
    	};
    	Install = { WantedBy = [ "graphical-session.target" ]; };
    };
}
