{ config, lib, pkgs, ... }:

{
  # 设置您的时区
  time.timeZone = "Asia/Shanghai";

  # 选择国际化属性
  i18n.defaultLocale = "en_US.UTF-8";
  # i18n.defaultLocale = "zh_CN.UTF-8";

  # 特殊应用的语言设置
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
    LANG = "zh_CN.UTF-8";
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
}
