{ config, lib, pkgs, ... }:

{
  # 通过 nmcli 或 nmtui 交互式配置网络连接
  networking.networkmanager.enable = true;

  # 让 NetworkManager 统一交给 resolved 管理
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # 本地域名解析
  networking.hosts = {
    # "127.0.0.1" = [ "localhost" "${config.networking.hostName}.localdomain" "${config.networking.hostName}" ];
    # "::1" = [ "localhost" ];
  };

  # DNS 服务器(最好不要把公网 DNS 写死在这里)
  networking.nameservers = [
    # "8.8.8.8"
    # "2001:4860:4860::8888"
    # "8.8.4.4"
    # "2001:4860:4860::8844"
  ];

  # # 只有当你确实有“本地 DNS 代理/转发器”时，才考虑插入它
  # # 例如 v2rayA/xray 提供的本地监听端口
  # networking.networkmanager.insertNameservers = [ "127.0.0.1" ];

  # 配置网络代理(如有必要)
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
