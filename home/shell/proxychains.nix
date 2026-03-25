{ config, pkgs, ...}:

{
    home.packages = with pkgs; [
        proxychains-ng
    ];

    # 代理分流配置(直接给出一份标准的本地代理配置)
    xdg.configFile."proxychains/proxychains.conf".text = ''
        # # 严格链式: 仅当列出的代理每一个都可用是启用(用于多级代理)
        # strict_chain
        # 动态回退: 只要有可用的代理即可
        dynamic_chain
        # 连 DNS 一同代理, 防止泄漏
        proxy_dns 

        remote_dns_subnet 224
        tcp_read_time_out 15000
        tcp_connect_time_out 8000
        [ProxyList]
        http    127.0.0.1   20172
    '';
}

