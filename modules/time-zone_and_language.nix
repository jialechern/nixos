{ config, lib, pkgs, ... }:

{
  # 设置您的时区
  time.timeZone = "Asia/Shanghai";

  # 选择国际化属性
  i18n.defaultLocale = "en_US.UTF-8";
  # i18n.defaultLocale = "zh_CN.UTF-8";

  # 特殊应用的语言设置
  # 注意: 不要在此写 LANG —— 上游用 { LANG = defaultLocale; } // extraLocaleSettings
  # 合并, 写在这里会覆盖 defaultLocale, 并在 /etc/locale.conf 多出一行 LANG=
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
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
}
