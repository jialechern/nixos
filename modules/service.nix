{ config, lib, pkgs, ... }:

let
  v2rayAssets = pkgs.symlinkJoin {
    name = "v2ray-assets";
    paths = [
      pkgs.v2ray-geoip
      pkgs.v2ray-domain-list-community
    ];
  };
in
{
  # 列出您想要启用的服务:
  # --- ssh ---
  # 启用 OpenSSH 守护进程
  services.openssh.enable = true;

  # --- 防火墙 ---
  # 在防火墙中开放端口
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # 或者完全禁用防火墙
  # networking.firewall.enable = false;

  # 注: 曾用 networking.firewall.trustedInterfaces = [ "virbr0" ] 放行 libvirt
  # 虚拟网桥, 但那等于放行 guest 直连宿主的所有端口; 没有实测需求, 已删除。
  # 若日后要让 guest 访问宿主上的某个服务, 开那个具体端口, 不要放行整个接口。

  # --- 其它 ---
  # 电源管理
  services.tlp.enable = true;

  # 代理工具
  services.v2raya = {
    enable = true;
    # --- 把内核换成 xray ---
    cliPackage = pkgs.xray;
  };

  # --- 注入对应的 dat 数据库 ---
  systemd.services.v2raya.environment = {
    V2RAYA_V2RAY_ASSETSDIR = "${v2rayAssets}/share/v2ray";
  };

  # --- 虚拟机 ---
  # 启用 libvirt 服务
  virtualisation.libvirtd.enable = true;

  # 注: /var/lib/qemu/firmware 由 libvirtd 模块自带的 tmpfiles 规则指向
  # qemu-ovmf-metadata (同一个目标路径后者生效, 实测本仓库这条会被覆盖),
  # 这里不再重复声明
  
  virtualisation.libvirtd.qemu.vhostUserPackages = with pkgs; [
    virtiofsd # 共享目录更顺手
  ];

  # --- 容器与沙箱 ---
  # Docker/Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # 将 docker 命令别名指向 podman
  };
  # Flatpak
  services.flatpak.enable = true;
}
