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

      // 华硕 TUF Gaming VG27AQML5A: 27 英寸 QHD (2560x1440) Fast IPS 电竞屏
      // 官方关键规格 (ASUS 规格页/用户手册):
      //   - 最大刷新率 300Hz: 仅 DP 1.4 (HBR3) + DSC 链路可达; 8bit@300Hz 数据率约 28.8Gbps,
      //     已超过 DP 1.4 有效带宽 25.92Gbps, 故 300Hz 必然依赖 DSC 压缩
      //   - 色深: 官方标称 1073.7M (10 bit), 实际为 8bit + FRC 面板 (第三方评测确认)
      //   - VRR: G-SYNC Compatible / AMD FreeSync Premium, 有效范围 48~300Hz (HDMI/DP 均支持)
      //   - 输入: DP 1.4 x1, HDMI 2.1 x2 (本机 HDMI 为 2.0 规格, 无法利用 2.1 特性),
      //     USB-C x1 (仅固件升级用)
      // 本机链路: 笔记本 MiniDP 口直连 dGPU (GTX 1650 Ti, 图灵, 支持 DP 1.4 + DSC)
      // 可用模式可通过 `niri msg outputs` 查询; 换线后用该命令确认 300Hz 已生效
      // 注意: 按 "制造商 型号 序列号" 匹配 (而非连接器名), 更换接口后配置依然生效;
      // 若日后更换同型号显示器导致失配, 可去掉序列号, 仅保留 "ASUSTek COMPUTER INC VG27AQML5A"

      // --- 外接屏 HDMI 口使用注意事项 (此前为 HDMI 连接, 现已改用 MiniDP) ---
      // 1. 本机 HDMI 口为 2.0 规格 (带宽 18Gbps): QHD 最高仅 144Hz (2560x1440@143.973),
      //    无法达到 300Hz (300Hz 需要 DP 1.4 + DSC 或 HDMI 2.1);
      // 2. NVIDIA 驱动不支持 HDMI 链路上的 VRR (G-Sync 仅限 DP): 该屏 EDID 在 HDMI 上也
      //    上报 VRR 支持, 此前在 HDMI 上启用 variable-refresh-rate 时, 静止画面 (如视频
      //    暂停帧) 处会反复 modeset 黑闪; 已用 `niri msg output <名称> vrr off` 实测确认
      //    (IPC 修改仅临时生效, 重启 niri 后恢复为配置行为); 若换回 HDMI 请注释掉下方
      //    输出块中的 variable-refresh-rate 行;
      // 3. HDMI 2.0 下色深与刷新率组合受带宽限制: 10bit 数据率比 8bit 多 25%,
      //    高刷与高色深不可兼得时优先保证刷新率;
      // 4. HDMI 连接时输出名可能为 HDMI-A-2: 因按 "制造商 型号 序列号" 匹配, 无需改配置,
      //    可用 `niri msg outputs` 查看实际名称与模式
      output "ASUSTek COMPUTER INC VG27AQML5A W7LMAS012273" {
          // 原生分辨率; 省略刷新率时 niri 自动选择当前链路下的最高刷新率
          // (HDMI: 144Hz, MiniDP: 300Hz, 无需在更换线材后修改配置)
          mode "2560x1440"
          scale 1.0
          // 物理上位于笔记本左侧, 故置于全局坐标空间最左侧 (x=0 为全局原点)
          position x=0 y=0
          // VRR (G-SYNC compatible): 当前为 MiniDP (DP-3) 链路, NVIDIA 驱动支持 DP 上的
          // VRR, 已在 300Hz 下实测正常 (niri msg outputs 显示 supported, enabled)。
          // 若日后在 DP 上出现低帧率黑闪/反复 modeset 等问题, 可改用按需模式:
          variable-refresh-rate on-demand=true
          // 并配合窗口规则按需启用 (详见 niri docs: variable-refresh-rate)
          // variable-refresh-rate
          // 若低帧率时光标卡顿, 可加 debug { disable-cursor-plane } 并重连显示器
          // 外接屏禁用热角 (25.11+), 避免误触 overview; 全局 gestures 开启后同样生效
          hot-corners {
              off
          }
          // 10bit 色深: 该屏为 8bit+FRC 面板, 华硕官方宣传 10bit (1073.7M 色)
          // niri 26.04 尚不支持 max-bpc 属性 (docs 标注 Since: next release, 当前版本
          // 解析未知属性会导致整份配置解析失败), 且 niri 目前默认强制 8bit 输出,
          // 故保持注释; 升级到支持版本后可取消注释。注意: 300Hz 下 8bit 已逼近
          // DP 1.4 带宽上限, 10bit 需要更高的 DSC 压缩比, 若启用后 300Hz 模式不可用
          // 属正常带宽限制, 可降为 240Hz 或换回 8bit; max-bpc 文档亦建议默认不设置,
          // 交由 GPU 驱动自动处理
          /- max-bpc 10
      }

      // 笔记本内置屏幕 (eDP-1)
      // 位于外接屏右侧: x = 外接屏逻辑宽度 2560 (scale 1.0 时逻辑尺寸 = 物理分辨率)
      output "eDP-1" {
          // 省略刷新率, 由 niri 自动选择该分辨率下的最高刷新率 (当前为 preferred 的
          // 60.056Hz); 若需显式指定, 刷新率必须与 `niri msg outputs` 完全一致
          // (精确到三位小数), 否则模式静默不生效
          mode "1920x1080"
          scale 1.0
          position x=2560 y=0
          // 启动时将焦点置于内置屏
          focus-at-startup
      }
    '';
  };
}
