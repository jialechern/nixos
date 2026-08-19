{ config, lib, pkgs, ... }:

{
  # 通过 nmcli 或 nmtui 交互式配置网络连接
  networking.networkmanager.enable = true;

  # 让 NetworkManager 统一交给 resolved 管理
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # 禁用 systemd-resolved 自己的 mDNS, 避免与本机 avahi 争抢发布 <hostname>.local
  # (两者同时开放 MulticastDNS 会导致 avahi 探测到"同名"而退让成 <hostname>-2.local 等)
  services.resolved.settings.Resolve.MulticastDNS = "no";

  # --- mDNS 本地域名解析 (.local) ---
  # 让局域网内其他设备的 <主机名>.local 可直接解析, 而不必记 IP。
  # 典型场景: 树莓派(Raspberry Pi OS 默认启用 avahi) -> raspberrypi.local。
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true; # 通过 nss-mdns 把 .local 解析交给 avahi (仅 IPv4 足够)
  services.avahi.publish = {
    enable = true; # 发布本机 <hostname>.local, 方便其他设备(如树莓派)反向访问
    addresses = true; # 发布本机 IP 地址记录, 否则其他设备只能发现名字、解析不到 IP
  };
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
