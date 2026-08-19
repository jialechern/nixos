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
  services.avahi.nssmdns4 = true; # 通过 nss-mdns 把 .local 解析交给 avahi (IPv4)
  services.avahi.nssmdns6 = true; # 通过 nss-mdns 把 .local 解析交给 avahi (IPv6)
  services.avahi.publish = {
    enable = true; # 发布本机 <hostname>.local, 方便其他设备(如树莓派)反向访问
    addresses = true; # 发布本机 IP 地址记录, 否则其他设备只能发现名字、解析不到 IP
  };
  # --- 入站防火墙放行 (NixOS 原生命令式防火墙, iptables 后端) ---
  # 注意: 部分服务模块会自动放行自己的端口, 无需在此重复:
  #   - services.openssh.enable -> 自动放行 22
  #   - programs.steam          -> 自动放行 27036/27037/10400/10401
  networking.firewall.allowedTCPPorts = [
    22    # SSH (openssh 也会自动放, 这里显式声明维护意图)
    5353  # mDNS 的 TCP fallback (非必需, 仅个别实现做大记录响应时用)
    20172 # v2raya HTTP 代理 (局域网设备经由此机代理上网, 需配合把监听地址改为 0.0.0.0)
  ];
  networking.firewall.allowedUDPPorts = [
    5353 # mDNS 广播/响应 (必须)
  ];
  # 默认对未放行端口为 DROP (静默丢弃), 更安全; 若想明确拒绝、让端口扫描
  # 更容易探出已开放端口, 可改为 networking.firewall.rejectPackets = true;

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
