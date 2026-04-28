# 编辑此配置文件以定义应在您的系统上安装哪些软件包.
# 如需帮助, 请查阅 configuration.nix(5) 手册页
# https://search.nixos.org/options 网站以及 NixOS 手册(可通过 `nixos-help` 命令查看)

{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    # 包含硬件扫描结果
    ./hardware-configuration.nix
  ];

  # 复制 NixOS 配置文件并将其链接到生成的系统中
  # (/run/current-system/configuration.nix). 这在您意外删除 configuration.nix 文件时非常有用
  # system.copySystemConfiguration = true;

  # 定义主机名, 可随时修改
  networking.hostName = "hp";

  # --- --- --- 文件系统 --- --- ---
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/01fd5fe3-4d40-4745-aa97-d770fb733965";
    fsType = "btrfs";
    options = [
      "defaults"
      "compress=zstd"
      "autodefrag"
      "discard=async"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/01fd5fe3-4d40-4745-aa97-d770fb733965";
    fsType = "btrfs";
    options = [
      "defaults"
      "compress=zstd"
      "autodefrag"
      "discard=async"
    ];
  };

  # --- --- --- 用户与组 --- --- ---
  users.groups.nix-users = { };
  users.users."${username}" = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "nix-users" "libvirtd" ];
  };

  users.users.root = {
    shell = pkgs.fish;
  };

  # 定义用户账户. 别忘了用 `passwd` 命令设置密码
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # --- --- --- End --- --- ---
  # 此选项定义您在此特定机器上安装的第一个 NixOS 版本
  # 用于保持与在旧版 NixOS 上创建的应用程序数据(例如数据库)的兼容性
  #
  # 大多数用户在任何情况下都 **绝对不应** 在初始安装后更改此值, 即使您已将系统升级到新的 NixOS 发行版
  #
  # 此值 **不会** 影响您获取软件包和操作系统的 Nixpkgs 版本, 因此更改它 **不会** 升级您的系统——关于如何实际进行升级
  #
  # 要实际执行此操作
  #
  # 此值低于当前 NixOS 发行版版本 **并不** 意味着您的系统已过时、不受支持或存在安全漏洞
  #
  # **请勿** 更改此值, 除非您已手动检查了它将为您的配置带来的所有更改, 并相应地迁移了您的数据
  #
  # 更多信息，请参阅 `man configuration.nix` 或 https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "25.11";
}

