{ config, pkgs, lib, inputs, hostName, ... }:

{
  # niri 主配置: 直接部署 flake 输入的 dotfiles 仓库
  xdg.configFile."niri" = {
    source = inputs.niri-dotfiles;
    recursive = true;
  };

  # 本机特定配置 (外接显示器等), 仅 omen 主机注入
  # 经 config.kdl 末行的 `include optional=true "conf.d/local-override.kdl"` 加载;
  # 该文件被 niri-dotfiles 仓库的 .gitignore ( **/local-* ) 忽略, 不会随 flake 输入分发,
  # 故由本仓库直接生成 (hostName 由各主机的 configuration.nix 经 extraSpecialArgs 注入)
  xdg.configFile."niri/conf.d/local-override.kdl" = lib.mkIf (hostName == "omen") {
    text = ''
      // local-override.kdl
      // 此处存放特定机器的特殊配置, 本文件由 /etc/nixos 仓库生成
      // (详见 home/desktop/niri.nix 的注入逻辑)
      // 本机: OMEN Laptop 15-ek0xxx (i7-10750H + Intel UHD + GTX 1650 Ti Mobile)

      // --- --- --- 外接显示器配置 --- --- ---

      // 外接显示器 (HDMI-A-2)
      // 华硕 TUF Gaming VG27AQML5A: 27 英寸 QHD (2560x1440) Fast IPS 电竞屏
      // 官方最大刷新率 300Hz (需 DP 1.4 / HDMI 2.1 链路),
      // 本机 HDMI 口为 2.0 规格, 链路协商下 QHD 最高仅 144Hz
      // 可用模式可通过 `niri msg outputs` 查询
      output "HDMI-A-2" {
          // 原生分辨率 + 当前 HDMI 链路下的最高刷新率
          // 注意: 刷新率须与 `niri msg outputs` 输出完全一致 (精确到三位小数)
          mode "2560x1440@144.000"
          scale 1.0
          // 物理上位于笔记本左侧, 故置于全局坐标空间最左侧 (x=0 为全局原点)
          position x=0 y=0
          // 该显示器支持 FreeSync/G-SYNC (见 `niri msg outputs` 中 VRR 支持情况), 启用可变刷新率
          // 若出现闪烁等异常, 可删除此行, 或改用 on-demand=true 仅对匹配窗口启用
          variable-refresh-rate
      }

      // 笔记本内置屏幕 (eDP-1)
      // 位于外接屏右侧: x = 外接屏逻辑宽度 2560 (scale 1.0 时逻辑尺寸 = 物理分辨率)
      output "eDP-1" {
          mode "1920x1080@60.056"
          scale 1.0
          position x=2560 y=0
          // 启动时将焦点置于内置屏
          focus-at-startup
      }
    '';
  };
}
