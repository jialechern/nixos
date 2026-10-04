{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # 引入 bootloader
    ./modules/boot-loader.nix
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
    # 引入 steam 通用配置
    ./modules/steam.nix
    # 引入主机名注入 Home Manager 的桥接配置
    ./modules/home-manager-hostname.nix
  ];

  # --- --- --- GPU 模块互斥守卫 --- --- ---
  # "每台机器只导入一个 GPU 模块" (见 AGENTS.md 的 Structure 一节) 以前只靠人肉检查:
  # 两模块同现时 services.xserver.videoDrivers / environment.variables 会因同名属性
  # 报冲突, 但 boot.kernelParams (intel)、hardware.graphics.extraPackages (intel) 与
  # hardware.nvidia.* (nvidia) 互不重叠, 会静默合并成一份半 nvidia 半 intel 的配置。
  # 这里用一个"取值唯一的 enum 选项"把该约定变成求值期错误 (只有本文件声明它,
  # 取值由两个 GPU 模块各自声明)。
  options.machine.gpu.driver = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [ "nvidia" "intel" ]);
    default = null;
    description = ''
      本机使用的 GPU 模块标识, 由 modules/nvidia.nix ("nvidia") 与
      modules/intel-extra.nix ("intel") 各自声明; 只在下面的断言里读取。
      用途: 同时导入两个 GPU 模块时取值冲突, 求值期即报错而不是静默合并。
    '';
  };

  config = {
    assertions = [
      {
        # 反向守卫: 新主机漏加 GPU 模块时立即报错 (默认 null, 所以用断言而非直接读)
        assertion = config.machine.gpu.driver != null;
        message = ''
          没有导入任何 GPU 模块: 请在该主机的 modules 列表里加入 ./modules/nvidia.nix
          (独显) 或 ./modules/intel-extra.nix (核显), 见 flake.nix 的 nixosConfigurations。
        '';
      }
    ];
  };
}
