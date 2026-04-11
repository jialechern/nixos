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

  networking.firewall.trustedInterfaces = [
    "virbr0" # 放行默认虚拟网桥
  ];

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

  systemd.tmpfiles.rules = [
    "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"
  ]; # 给 virt-manager / libvirt 提供 UEFI 固件
  
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
