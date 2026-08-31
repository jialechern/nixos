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
          // VRR (niri msg outputs 显示 supported)。此处采用 on-demand 模式: 仅当输出上
          // 存在匹配 variable-refresh-rate 窗口规则的窗口时才启用 VRR, 平时显示
          // "disabled" 属正常 (2026-08 排查时未配置该窗口规则, 故 VRR 在游戏中从未
          // 实际激活, 这也是当时实测 VRR 无效的原因); 若需 VRR 对游戏生效, 需在
          // window-rule 中为游戏窗口添加 variable-refresh-rate 匹配:
          variable-refresh-rate on-demand=true
          // 全局常开写法 (此前在 DP 上实测正常; 不推荐, 静止画面可能触发 modeset 黑闪):
          // variable-refresh-rate
          // 若低帧率时光标卡顿, 可加 debug { disable-cursor-plane } 并重连显示器
          // 外接屏禁用热角 (25.11+), 避免误触 overview; 全局 gestures 开启后同样生效
          hot-corners {
              off
          }
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

      // --- --- --- 统一使用 NVIDIA 显卡渲染 --- --- ---
      // 如不统一渲染:
      //   niri 默认取第一个 DRM 设备的渲染节点 (本机为 Intel renderD128), 而外接屏
      //   扫描输出在 NVIDIA card0 (PRIME Sync 拓扑)。全屏 direct scanout 时, Intel 渲染
      //   的帧需跨 GPU 交给 NVIDIA 扫描, NVIDIA 驱动该路径的 explicit sync fence 处理
      //   有 bug (niri issue #2477), 帧会在扫描中途被换 → 撕裂; eDP-1 与渲染同 GPU 故无恙。
      //   也会因撕裂源于 fence 时序而非刷新率失配, VRR 与降刷新率均无法改善。
      // 修复: 强制 niri 在 NVIDIA renderD129 渲染, 外接屏渲染+扫描同 GPU, 消除跨 GPU
      //   传输; 实施后双屏全屏游戏均正常。
      debug {
          // renderD129 = NVIDIA (GTX 1650 Ti); 确认方法: `ls -l /dev/dri/by-path`
          // (pci-0000:01:00.0-render -> ../renderD129), 换显卡/平台后需重新确认
          render-drm-device "/dev/dri/renderD129"
      }
      // 注意:
      // - 启动时选定渲染设备, 热重载不生效, 修改后须重启 niri 会话;
      // - 验证: journalctl --user -u niri -b | grep "render node" 显示 renderD129
      //   (修复前为 renderD128);
      // - 副作用: 内置屏变为 NVIDIA 渲染 → Intel 扫描 (反向跨 GPU), 实测正常;
      //   PRIME Sync 下 NVIDIA 本就全程通电, 功耗影响可忽略;
      // - debug 选项不受 niri 配置兼容性政策保护, 升级 niri 后建议复核;
      // - 回退: 驱动修复或换 AMD 后可删本块; 备选 debug { disable-direct-scanout }
      //   (全屏也走合成路径, 保持全屏, 性能损失很小)。
    '';
  };
}
