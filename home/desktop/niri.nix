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

      // 外接显示器 (HDMI-A-2, 计划改用 MiniDP)
      // 华硕 TUF Gaming VG27AQML5A: 27 英寸 QHD (2560x1440) Fast IPS 电竞屏
      // 官方最大刷新率 300Hz (需 DP 1.4 / HDMI 2.1 链路, 300Hz 依赖 DSC)
      // 本机 HDMI 口为 2.0 规格, QHD 最高仅 144Hz;
      // GTX 1650 Ti (图灵) 支持 DP 1.4 + DSC, 换用 MiniDP 后可达到 300Hz
      // 可用模式可通过 `niri msg outputs` 查询; 换线后用该命令确认 300Hz 已生效
      // 注意: 按 "制造商 型号 序列号" 匹配 (而非连接器名), 更换接口后配置依然生效
      output "ASUSTek COMPUTER INC VG27AQML5A W7LMAS012273" {
          // 原生分辨率; 省略刷新率时 niri 自动选择当前链路下的最高刷新率
          // (HDMI: 144Hz, MiniDP: 300Hz, 无需在更换线材后修改配置)
          mode "2560x1440"
          scale 1.0
          // 物理上位于笔记本左侧, 故置于全局坐标空间最左侧 (x=0 为全局原点)
          position x=0 y=0
          // VRR (FreeSync/G-Sync): 该屏 EDID 在 HDMI 上也上报 VRR 支持, 但 NVIDIA 驱动
          // 不支持 HDMI 链路上的 VRR (G-Sync 仅限 DP)。此前启用 variable-refresh-rate 时,
          // niri 在 HDMI 上持续尝试 VRR, 静止画面 (如视频暂停帧) 处会反复 modeset 黑闪;
          // 已用 `niri msg output HDMI-A-2 vrr off` 实测确认, 关闭后恢复正常。
          // 换用 MiniDP 后取消下一行注释即可重新启用 (DP + NVIDIA 才是正常的 G-Sync 链路)
          // variable-refresh-rate
          // 若低帧率时光标卡顿, 可加 debug { disable-cursor-plane } 并重连显示器
          // 外接屏禁用热角 (25.11+), 避免误触 overview; 全局 gestures 开启后同样生效
          hot-corners {
              off
          }
          // 10bit 色深 (该屏原生 10bit, 华硕官方规格): niri 暂不支持此属性
          // (docs 标注 Since: next release, 当前 26.04 遇到未知属性会导致整份配置解析失败)
          // 升级到支持版本后取消注释即可; 注意 HDMI 2.0 下 10bit@144Hz 带宽不足 (需 4:2:2),
          // 建议换 MiniDP 后再启用
          /- max-bpc 10
      }

      // 笔记本内置屏幕 (eDP-1)
      // 位于外接屏右侧: x = 外接屏逻辑宽度 2560 (scale 1.0 时逻辑尺寸 = 物理分辨率)
      output "eDP-1" {
          // 刷新率必须与 `niri msg outputs` 完全一致 (精确到三位小数), 否则模式静默不生效;
          // 若面板支持更高刷新率 (如 144Hz 版), 可省略 @60.056 让 niri 自动选最高
          mode "1920x1080"
          scale 1.0
          position x=2560 y=0
          // 启动时将焦点置于内置屏
          focus-at-startup
      }
    '';
  };
}
