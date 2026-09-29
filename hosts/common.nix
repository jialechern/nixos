# 两台主机 (omen / hp) 共用的系统级配置。
#
# 背景 (复评 RED-14): 两份 hosts/*/configuration.nix 曾几乎逐字相同, 公共项要改两处、
# 易漏改一台; 这里把公共部分收敛成一份, 主机自己的 configuration.nix 只保留:
#   - hardware-configuration.nix 的导入
#   - networking.hostName
#   - 将来只属于该机器的差异项
{ lib, pkgs, username, ... }:

{
  # 复制 NixOS 配置文件并将其链接到生成的系统中
  # (/run/current-system/configuration.nix). 这在您意外删除 configuration.nix 文件时非常有用
  # system.copySystemConfiguration = true;

  # --- --- --- 文件系统 --- --- ---
  # 存储布局 (device / fsType / subvol=...) 由 hardware-configuration.nix 定义
  # (生成文件的职责; nixos-generate-config 对 btrfs 只输出 subvol, 不含压缩等选项);
  # 这里只追加配置性挂载选项 —— options 是 list 合并, 不会覆盖生成文件里的 subvol=@。
  # 注意: 别因为这里"看起来完整"就删掉 hw-cfg 里的条目, subvol 只在那里, 删了挂载会失败。
  # (两台机器共用同一套 btrfs 子卷布局, 见 README 安装流程; 若新机器布局不同,
  #  在自己的 configuration.nix 里用 lib.mkForce 覆盖对应 options)
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
  # 用 mkDefault: 两台机器同为 25.11, 共享此默认值; 将来新装机器若初始版本不同,
  # 在自己的 configuration.nix 里直接赋 system.stateVersion 即可覆盖 (mkDefault 优先级最低)。
  system.stateVersion = lib.mkDefault "25.11";
}
