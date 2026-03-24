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
  };

  # Outputs (输出): 定义系统配置
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # 系统架构
      system = "x86_64-linux";

      # 用户名
      username = "jlc";
    in
    {
      # 注意这里: 从 homeConfigurations 变成了 nixosConfigurations
      nixosConfigurations = {
        # "nixos" 是主机名 (hostname), 可以根据不同机器改成不同的名字
        "nixos" = nixpkgs.lib.nixosSystem {
          inherit system;

          # 将 inputs 和 username 传递给所有的 NixOS 系统级模块
          specialArgs = { inherit inputs username; };

          modules = [
            # 系统的核心配置和硬件配置 (系统自动生成)
            ./configuration.nix

            # 将 Home Manager 作为 NixOS 的一个子模块无缝嵌入
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
