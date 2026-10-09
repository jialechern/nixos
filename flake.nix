{
  description = "JLC's NixOS & Home Manager Configuration";

  # Inputs (输入): 定义的依赖来源
  inputs = {
    # 使用清华大学镜像源
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable";

    # 引入 Home Manager, 并强制它使用上面定义的 nixpkgs 版本, 防止版本冲突
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 引入 sops-nix 源
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 引入 pi 上游官方 flake
    # 上游只提供 packages / apps / overlay, 没有 home-manager 模块; 仓库能写
    # programs.pi-coding-agent.* 是因为 home-manager 上游自带该模块, 这里只是
    # "加 input + 用它提供的 package 覆盖点", 不走上游 overlay (那只产生
    # pkgs.pi, 不会替换 pkgs.pi-coding-agent)。
    # stable 分支由上游发版 workflow 快进到最新正式 tag, 因此它的 tip 即最新正式版。
    pi = {
      url = "github:earendil-works/pi/stable";

      # 上游这两项都指向 GitHub, follows 到本机清华镜像 nixpkgs:
      # 省下一次完整 nixpkgs 下载。上游依赖 hash 取自其 package-lock.json 的
      # integrity (与 nixpkgs rev 无关), 但 nodejs / importNpmLock / 各 setup hook
      # 仍随被 follow 的 nixpkgs 走 —— 换 rev 后需重新验证上游包能否构建
      inputs.nixpkgs.follows = "nixpkgs";

      # 只在 x86_64-darwin 分支才会被用到, 本机 (x86_64-linux) 跟随无副作用
      inputs.nixpkgs-darwin-x64.follows = "nixpkgs";
    };
  };

  # Outputs (输出): 定义系统配置
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      ...
    }@inputs:
    let
      # 系统架构
      system = "x86_64-linux";

      # 用户名
      username = "jlc";

      # 引入必要的库
      lib = nixpkgs.lib;
    in
    {
      # 注意这里: 从 homeConfigurations 变成了 nixosConfigurations
      nixosConfigurations = {
        # "omen" / "hp" 是主机名 (hostname), 可以根据不同机器改成不同的名字

        "omen" = nixpkgs.lib.nixosSystem {
          inherit system;

          # 将 inputs 和 username 传递给所有的 NixOS 系统级模块
          specialArgs = { inherit inputs username; };

          modules = lib.flatten [
            # 系统的核心配置和硬件配置 (系统自动生成)
            ./hosts/omen/configuration.nix
            # 引入 nvidia 驱动
            ./modules/nvidia.nix
            # 引入默认配置
            ./modules.nix
            # 引入需要网络代理的系统依赖
            # 注意: pathExists 只看 git 已索引的文件 —— 新增该文件后必须先 `git add`,
            # 否则开关静默为 false (flake 源只拷贝 tracked 文件)
            (lib.optional (builtins.pathExists ./modules/system-dependencies-require-proxy.nix) ./modules/system-dependencies-require-proxy.nix)

            # 将 Home Manager 作为 NixOS 的一个子模块嵌入
            home-manager.nixosModules.home-manager
            {
              # 让 Home Manager 复用 NixOS 全局的 pkgs 实例 (包含允许 non-free 的设置)
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # 将所有的 inputs 传递给各个 .nix 模块
              home-manager.extraSpecialArgs = { inherit inputs username; };

              # 核心模块引入: 直接指向你现有的 home.nix 入口
              home-manager.users.${username} = import ./home.nix;
            }
          ];
        };

        "hp" = nixpkgs.lib.nixosSystem {
          inherit system;

          # 将 inputs 和 username 传递给所有的 NixOS 系统级模块
          specialArgs = { inherit inputs username; };

          modules = lib.flatten [
            # 系统的核心配置和硬件配置 (系统自动生成)
            ./hosts/hp/configuration.nix
            # 引入默认配置
            ./modules.nix
            # 引入 intel 核显配置
            ./modules/intel-extra.nix
            # 引入需要网络代理的系统依赖
            # 注意: pathExists 只看 git 已索引的文件 —— 新增该文件后必须先 `git add`,
            # 否则开关静默为 false (flake 源只拷贝 tracked 文件)
            (lib.optional (builtins.pathExists ./modules/system-dependencies-require-proxy.nix) ./modules/system-dependencies-require-proxy.nix)

            # 将 Home Manager 作为 NixOS 的一个子模块嵌入
            home-manager.nixosModules.home-manager
            {
              # 让 Home Manager 复用 NixOS 全局的 pkgs 实例 (包含允许 non-free 的设置)
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # 将所有的 inputs 传递给各个 .nix 模块
              home-manager.extraSpecialArgs = { inherit inputs username; };

              # 核心模块引入: 直接指向你现有的 home.nix 入口
              home-manager.users.${username} = import ./home.nix;
            }
          ];
        };

      };

    };
}
