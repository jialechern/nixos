{ config, lib, pkgs, inputs, ... }:

{
  nix = {
    settings = {
      # 每次构建错误时显示详细信息
      show-trace = true;
      # 开启实验性功能: Flakes 和新的 Nix 命令
      experimental-features = [ "nix-command" "flakes" ];
      # 国内镜像源
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
      # 可信的公钥
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      # 允许使用 nix 的用户和组
      trusted-users = [ "root" "@wheel" "@nix-users" ];
      # 自动优化 /nix/store 的磁盘使用
      auto-optimise-store = true;
      # 设为 false 后, 当配置文件没有 git commit 时, 不再弹出烦人的警告
      warn-dirty = false;
      # 限制构建任务使用的核心数 (根据的 CPU 自行调整, 0 为使用全部)
      max-jobs = "auto";
      cores = 0;
    };
  
    # 开启系统级的 nix 垃圾回收
    gc = {
      automatic = true;
      # 每七天运行一次垃圾回收
      dates = "weekly";
  
      # # 自动删除超过 7 天的世代
      # ptions = "--delete-older-than 7d";
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
