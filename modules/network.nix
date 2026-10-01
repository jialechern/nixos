{
  config,
  lib,
  pkgs,
  ...
}:

{
  # 通过 nmcli 或 nmtui 交互式配置网络连接
  networking.networkmanager.enable = true;

  # 让 NetworkManager 统一交给 resolved 管理
  # (启用 resolved 时上游模块会自动设 networking.networkmanager.dns, 无需手写)
  services.resolved.enable = true;

  # 禁用 systemd-resolved 自己的 mDNS, 避免与本机 avahi 争抢发布 <hostname>.local
  # (两者同时开放 MulticastDNS 会导致 avahi 探测到"同名"而退让成 <hostname>-2.local 等)
  services.resolved.settings.Resolve.MulticastDNS = "no";

  # --- mDNS 本地域名解析 (.local) ---
  # 让局域网内其他设备的 <主机名>.local 可直接解析, 而不必记 IP。
  # 典型场景: 树莓派(Raspberry Pi OS 默认启用 avahi) -> raspberrypi.local。
  services.avahi.enable = true;
  services.avahi.openFirewall = true; # 自动放行 UDP 5353 (mDNS), 不必手工列端口
  services.avahi.nssmdns4 = true; # 通过 nss-mdns 把 .local 解析交给 avahi (IPv4)
  services.avahi.nssmdns6 = true; # 通过 nss-mdns 把 .local 解析交给 avahi (IPv6)
  services.avahi.publish = {
    enable = true; # 发布本机 <hostname>.local, 方便其他设备(如树莓派)反向访问
    addresses = true; # 发布本机 IP 地址记录, 否则其他设备只能发现名字、解析不到 IP
  };
  # --- 入站防火墙放行 (NixOS 原生命令式防火墙, iptables 后端) ---
  # 注意: 部分服务模块会自动放行自己的端口, 无需在此重复:
  #   - services.openssh.enable -> 自动放行 22
  #   - programs.steam          -> UDP 27036 (Peer discovery; localNetworkGameTransfers 或
  #                                remotePlay 的 openFirewall 任一开启即放行);
  #                                remotePlay.openFirewall 另加 TCP 27036/27037 +
  #                                UDP 10400/10401 + UDP 27031-27035
  #   - services.avahi          -> openFirewall = true 时自动放行 UDP 5353 (见上)
  # mDNS 只用 UDP (实测本机无 TCP:5353 监听), 所以不再手工放行 TCP 5353。
  networking.firewall.allowedTCPPorts = [
    22 # SSH (openssh 也会自动放, 这里显式声明维护意图)
    20172 # v2raya HTTP 代理 (局域网设备经由此机代理上网, 需配合把监听地址改为 0.0.0.0)
  ];
  # 默认对未放行端口为 DROP (静默丢弃), 更安全; 若想明确拒绝、让端口扫描
  # 更容易探出已开放端口, 可改为 networking.firewall.rejectPackets = true;

  # 本地域名解析
  networking.hosts = {
    # "127.0.0.1" = [ "localhost" "${config.networking.hostName}.localdomain" "${config.networking.hostName}" ];
    # "::1" = [ "localhost" ];
  };

  # DNS 服务器: 不要在这里写死公网 DNS (会绕过 resolved / NetworkManager 的按连接下发)。
  # 注意空列表会渲染出空的 DNS= 行, 所以需要时再整块打开:
  # networking.nameservers = [ "8.8.8.8" "2001:4860:4860::8888" ];

  # # 只有当你确实有“本地 DNS 代理/转发器”时，才考虑插入它
  # # 例如 v2rayA/xray 提供的本地监听端口
  # networking.networkmanager.insertNameservers = [ "127.0.0.1" ];

  # 配置网络代理(如有必要)
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
