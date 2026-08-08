{ config, lib, ... }:

{
  # 将主机名自动注入 Home Manager 模块参数
  # 供 home/ 下的模块 (如 desktop/niri.nix) 按主机区分行为,
  # 无需在每个主机的 configuration.nix 中重复设置
  # (与 flake.nix 中设置的 home-manager.extraSpecialArgs 自动合并)
  home-manager.extraSpecialArgs.hostName = config.networking.hostName;
}
