{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  nix = {
    settings = {
      # 每次构建错误时显示详细信息
      show-trace = true;
      # 开启实验性功能: Flakes 和新的 Nix 命令
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # 国内镜像源 (只列额外的即可 —— cache.nixos.org 由 nixpkgs 默认提供,
      # 此选项是合并语义, 重复列会在生效值里出现两次)
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
      ];
      # 可信的公钥: 只列额外项 —— cache.nixos.org 的公钥由 nixpkgs 默认提供
      # (此选项是合并语义, 重复列只会在最终配置里出现两遍)
      # 允许使用 nix 的用户和组。root 由默认提供; @wheel 已覆盖本机唯一用户,
      # 再列 @nix-users 没有收益 (加入 trusted-users 等价于给 root 权限)
      trusted-users = [ "@wheel" ];
      # 自动优化 /nix/store 的磁盘使用
      auto-optimise-store = true;
      # 设为 false 后, 当配置文件没有 git commit 时, 不再弹出烦人的警告
      warn-dirty = false;
      # 构建并行度保持默认: max-jobs 默认即按 CPU 数自动决定, 无需显式写在配置里。
      # 需要限制时再打开下面两行之一:
      # max-jobs = 4;  # 同时构建的任务数
      # cores = 0;     # 每个任务内部使用的核心数 (0 = 全部)
    };

    # 开启系统级的 nix 垃圾回收
    gc = {
      automatic = true;
      # 每七天运行一次垃圾回收
      dates = "weekly";

      # 自动删除超过 7 天的世代
      options = "--delete-older-than 7d";
    };

    registry = {
      # 将命令行的 nixpkgs 映射到 Flake 锁定的那个 nixpkgs
      # 前提是 home.nix 能接收到 flake 的 inputs 参数
      nixpkgs.flake = inputs.nixpkgs;
    };
  };

  # --- nix 代理设置 ---
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:20172";
    https_proxy = "http://127.0.0.1:20172";
    ftp_proxy = "http://127.0.0.1:20172";
    no_proxy = "localhost,127.0.0.1,::1";
  };
}
