{ osConfig, pkgs, ... }:

{
  home.packages = with pkgs; [
    proxychains-ng
  ];

  # 代理分流配置: proxychains-ng 仅自动读取 ~/.proxychains/proxychains.conf
  # (不读取 XDG 路径, 之前放 xdg.configFile 导致回退到包内默认配置而失效),
  # 故部署到该位置, 使 `proxychains4 <命令>` 开箱即用。
  # 地址/端口经 osConfig 从 modules/proxy.nix 的 machine.proxy 读取
  # (Home Manager 作为 NixOS 子模块时得到的特殊参数, 见 HM 的 nixos/common.nix)。
  home.file.".proxychains/proxychains.conf".text = ''
    # 动态回退: 只要有可用的代理即可
    dynamic_chain
    # 连 DNS 一同代理, 防止泄漏
    proxy_dns

    remote_dns_subnet 224
    tcp_read_time_out 15000
    tcp_connect_time_out 8000
    [ProxyList]
    http    ${osConfig.machine.proxy.clientHost}   ${toString osConfig.machine.proxy.httpPort}
  '';
}
