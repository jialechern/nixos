{ config, lib, pkgs, ... }:

{
  # 通过 nmcli 或 nmtui 交互式配置网络连接
  networking.networkmanager.enable = true;

  # 本地域名解析
  networking.hosts = {
    "127.0.0.1" = [ "localhost" "${config.networking.hostName}.localdomain" "${config.networking.hostName}" ];
    "::1" = [ "localhost" ];
  };

  # DNS 服务器
  networking.nameservers = [
    "8.8.8.8"
    "2001:4860:4860::8888"
    "8.8.4.4"
    "2001:4860:4860::8844"
  ];

  # 配置网络代理(如有必要)
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
