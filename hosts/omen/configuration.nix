# 本机 (omen) 专属配置; 两台主机共用的部分见 ../common.nix
# 编辑此文件以添加只属于本机的软件包/服务; 选项查询:
# https://search.nixos.org/options 或 `nixos-help`
{ ... }:

{
  imports = [
    # 两台主机共用的系统级配置 (文件系统挂载选项 / 用户与组 / stateVersion)
    # 注: 这里的顺序有实际影响 —— common.nix 的 fileSystems.options 与 hw-cfg 的
    # subvol 按 list 合并, 顺序决定生成的挂载选项排列, 调整会改变最终 drv。
    ../common.nix
    # 包含硬件扫描结果
    ./hardware-configuration.nix
  ];

  # 定义主机名, 可随时修改
  networking.hostName = "omen";
}
