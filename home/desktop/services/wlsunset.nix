{ config, pkgs, ... }:

{
  services.wlsunset = {
    enable = true;
    latitude = "40.0"; # 替换为你的纬度
    longitude = "116.0"; # 替换为你的经度
    temperature.night = 4000; # (4000 是 HM 默认值, 保留以便日后调整)
  };
}

