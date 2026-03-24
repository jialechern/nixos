{ config, pkgs, ... }:

{
    services.wlsunset = {
        enable = true;
        latitude = "40.0";      # 替换为你的纬度
        longitude = "116.0";    # 替换为你的经度
        temperature.night = 4000;
    };
}

