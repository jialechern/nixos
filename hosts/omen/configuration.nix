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
  networking.hostName = "omen";

  # --- --- --- 文件系统 --- --- ---
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/63088d49-836a-40b8-9e99-aa987455ca7f";
    fsType = "btrfs";
    options = [
      "defaults"
      "compress=zstd"
      "autodefrag"
      "discard=async"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0abb0e77-a3f1-46e5-a054-3e0c48069f28";
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
    shell = pkgs.bashInteractive;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "nix-users" "libvirtd" ];
  };

  users.users.root = {
    shell = pkgs.bashInteractive;
  };

  # 用户账户定义在 flake.nix (单用户 jlc); 首次登录后可用 `passwd` 改密码

  # --- --- --- End --- --- ---
  # stateVersion: 首次安装这个系统时的 NixOS 版本, 升级后不要随手改
  # (它会改变若干选项的默认值与数据迁移行为)。当前 25.11 而 nixpkgs 已是 26.11 代 ——
  # 要 bump 时先读 rl-2605 / rl-2611 的 release notes 并逐项验证
  # (已知会影响本仓库的: HM xdg.userDirs.setSessionVariables 默认值翻转)
  system.stateVersion = "25.11";
}

