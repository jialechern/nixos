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
        # "omen" 是主机名 (hostname), 可以根据不同机器改成不同的名字
        "omen" = nixpkgs.lib.nixosSystem {
          inherit system;

          # 将 inputs 和 username 传递给所有的 NixOS 系统级模块
          specialArgs = { inherit inputs username; };

          modules = [
            # 系统的核心配置和硬件配置 (系统自动生成)
            ./hosts/omen/configuration.nix
            # 引入 bootloader
            ./modules/boot-loader.nix
            # 引入 nvidia 驱动
            ./modules/nvidia.nix
            # 开启硬件图形化加速
            ./modules/hardware-graphics.nix
            # 引入 nix 配置
            ./modules/nix-config.nix
            # 引入网络配置
            ./modules/network.nix
            # 引入基本外设配置
            ./modules/peripherals.nix
            # 引入时区与语言配置
            ./modules/time-zone_and_language.nix
            # 引入桌面环境配置
            ./modules/desktop.nix
            # 引入输入法与字体配置
            ./modules/input-method_and_font.nix
            # 引入常见的系统级服务
            ./modules/service.nix
            # 引入系统必要的软件与工具
            ./modules/software_and_tool.nix

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
