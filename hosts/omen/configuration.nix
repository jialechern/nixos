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
  # 存储布局 (device / fsType / subvol=...) 由 hardware-configuration.nix 定义
  # (生成文件的职责; nixos-generate-config 对 btrfs 只输出 subvol, 不含压缩等选项);
  # 这里只追加配置性挂载选项 —— options 是 list 合并, 不会覆盖生成文件里的 subvol=@。
  # 注意: 别因为这里"看起来完整"就删掉 hw-cfg 里的条目, subvol 只在那里, 删了挂载会失败。
  fileSystems."/".options = [
    "defaults"
    "compress=zstd"
    "autodefrag"
    "discard=async"
  ];

  fileSystems."/home".options = [
    "defaults"
    "compress=zstd"
    "autodefrag"
    "discard=async"
  ];

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
  # (已知会影响本仓库的: HM xdg.userDirs.setSessionVariables 默认值翻转;
  #  programs.zsh.dotDir 在 xdg.enable 下默认从 $HOME 迁到 ~/.config/zsh,
  #  .zshrc / .zsh_history 随之迁移)
  system.stateVersion = "25.11";
}

