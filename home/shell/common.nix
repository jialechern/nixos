# shell 的共享配置:
# 通用别名与 PATH 只在此定义一次, 避免在每个 shell 文件里重复
{ config, pkgs, ... }:

let
  # --- niri-gpu: 检查当前 niri 会话实际用哪块 GPU 渲染 ---
  # 背景: 本机为 Intel 核显 + NVIDIA 独显 (PRIME Sync)。niri 启动时若 NVIDIA 渲染
  # 节点尚未就绪会静默回退核显, 且渲染设备在启动时选定、热重载不生效 (详见
  # home/desktop/niri.nix), 故需要一条命令随时确认现状。
  # 判定链路 (不可简化为单个 grep):
  #   1. 以 niri 自身日志 "using as the render node" 为权威判据 —— 注意它打印的是
  #      解析后的 renderD 编号, 而非配置里的 by-path 路径; DEBUG 级的
  #      "got render node" 只是设备枚举, 用它会把核显误判为渲染设备;
  #   2. 经 /dev/dri/by-path 反查 PCI 地址 (不硬编码 renderD 编号, 重启后仍有效);
  #   3. 读 /sys/bus/pci/devices/<pci>/vendor 判厂商, lspci 仅用于显示型号。
  # 退出码: 0 = 期望 GPU 渲染, 1 = 其他 GPU 渲染 (多半是核显回退), 2 = 无法判定
  niriGpu = pkgs.writeShellApplication {
    name = "niri-gpu";
    runtimeInputs = with pkgs; [
      coreutils # readlink / cat / head / tail
      gnugrep # grep
      gnused # sed
      pciutils # lspci
      procps # pgrep
      systemd # journalctl
    ];
    text = ''
      # niri-gpu: 检查当前 niri 会话实际用于渲染的 GPU
      #
      # 判定链路:
      #   1. 从当前 niri 进程的 journal 取 niri 自己打印的 "using as the render node" (INFO 级);
      #      注意 niri 打印的是解析后的 /dev/dri/renderD* 编号, 而非配置中的 by-path 路径;
      #      DEBUG 级的 "got render node" 是设备枚举, 不可作为判据。
      #   2. readlink -f 归一化后, 在 /dev/dri/by-path/ 反查对应的 PCI 地址 (避免硬编码 minor 号)。
      #   3. 读 /sys/bus/pci/devices/<pci>/vendor 判厂商, lspci 仅用于显示型号。
      #
      # 退出码: 0 = 期望 GPU 渲染; 1 = 其他 GPU 渲染 (多半是核显回退); 2 = 无法判定

      set -euo pipefail

      # 期望用于渲染的 GPU 的 PCI vendor: 0x10de = NVIDIA (本机 dGPU); 换 A 卡改为 0x1002
      EXPECTED_VENDOR=0x10de

      usage() {
        cat <<'EOF'
      用法: niri-gpu [-q|-h]
        -q, --quiet  仅输出一行结论 (便于脚本/waybar 调用)
        -h, --help   显示帮助
      退出码: 0=期望 GPU 渲染, 1=其他 GPU 渲染, 2=无法判定
      EOF
      }

      quiet=0
      case "''${1:-}" in
        -q | --quiet) quiet=1 ;;
        -h | --help)
          usage
          exit 0
          ;;
        "") ;;
        *)
          usage >&2
          exit 2
          ;;
      esac

      die() {
        printf 'niri-gpu: %s\n' "$*" >&2
        exit 2
      }

      vendor_name() {
        case "$1" in
          0x10de) printf 'NVIDIA' ;;
          0x8086) printf 'Intel' ;;
          0x1002) printf 'AMD' ;;
          *) printf '未知厂商(%s)' "$1" ;;
        esac
      }

      vendor_kind() {
        case "$1" in
          0x10de) printf '独显' ;;
          0x8086) printf '核显' ;;
          *) printf 'GPU' ;;
        esac
      }

      # --- 1. 当前 niri 进程 ---
      pid="$(pgrep -x niri | head -n1 || true)"
      [ -n "$pid" ] || die "未发现运行中的 niri 进程"

      # --- 2. 取该进程日志中的渲染节点 ---
      render="$(
        journalctl --user "_PID=$pid" --no-pager -o cat 2>/dev/null |
          grep -a 'using as the render node' | tail -n1 |
          grep -a -o '/dev/dri/[0-9A-Za-z/._:-]*' || true
      )"
      # 回退: 按 PID 查不到时 (如日志已轮转), 取本次启动中最后一次记录
      if [ -z "$render" ]; then
        render="$(
          journalctl --user -u niri -b --no-pager -o cat 2>/dev/null |
            grep -a 'using as the render node' | tail -n1 |
            grep -a -o '/dev/dri/[0-9A-Za-z/._:-]*' || true
        )"
      fi
      [ -n "$render" ] || die "niri 日志中没有 'using as the render node' 记录"

      node="$(readlink -f "$render" 2>/dev/null || true)"
      [ -n "$node" ] || die "渲染节点不存在: $render"

      # --- 3. render node 反查 PCI 地址, 并统计本机 GPU 数量 ---
      pci=""
      bypath=""
      gpu_count=0
      for link in /dev/dri/by-path/pci-*-render; do
        if [ -e "$link" ]; then
          gpu_count=$((gpu_count + 1))
          if [ "$(readlink -f "$link")" = "$node" ]; then
            bypath="$link"
            pci="''${link##*/pci-}"
            pci="''${pci%-render}"
          fi
        fi
      done
      [ -n "$pci" ] || die "无法把 $node 映射到 PCI 地址 (by-path 链接缺失?)"

      # --- 4. 厂商与型号 ---
      vendor_file="/sys/bus/pci/devices/$pci/vendor"
      [ -r "$vendor_file" ] || die "找不到 $vendor_file"
      vendor="$(cat "$vendor_file")"
      name="$(vendor_name "$vendor")"
      kind="$(vendor_kind "$vendor")"
      model="$(lspci -D -s "$pci" 2>/dev/null | sed 's/^[^ ]* //' || true)"
      [ -n "$model" ] || model="(lspci 未提供信息)"

      if [ "$vendor" = "$EXPECTED_VENDOR" ]; then
        rc=0
        mark="✅ 符合预期"
      elif [ "$gpu_count" -le 1 ]; then
        rc=0
        mark="✅ 本机仅此一块 GPU, 不存在回退"
      else
        rc=1
        mark="❌ 不符合预期"
      fi

      if [ "$quiet" -eq 1 ]; then
        printf '%s %s (%s) %s\n' "$kind" "$name" "$pci" "$mark"
        exit "$rc"
      fi

      printf 'niri 进程  : %s\n' "$pid"
      printf '渲染节点   : %s\n' "$node"
      printf 'by-path    : %s\n' "$bypath"
      printf 'PCI 地址   : %s\n' "$pci"
      printf 'GPU 型号   : %s\n' "$model"
      printf 'GPU 厂商   : %s (%s)\n' "$name" "$vendor"
      printf '结论       : %s %s 渲染 %s\n' "$kind" "$name" "$mark"
      if [ "$rc" -eq 1 ]; then
        printf '             常见原因: 开机竞态导致 niri 回退到核显渲染;\n'
        printf '             可重启 niri 会话, 并检查 niri.service 的 wait-nvidia drop-in。\n'
      fi
      exit "$rc"
    '';
  };
in
{
  # --- 通用别名: home.shellAliases 自动注入所有已启用的 shell ---
  home.shellAliases = {
    ff = "fastfetch";
    rsync = "rsync -arvP";
    px = "proxychains4 -q";
    ngens = "nix profile history --profile /nix/var/nix/profiles/system";
    cliph = "cliphist list | fzf | cliphist decode | wl-copy";
    tm = "tmux new-session -A -s main";
    # 检查 niri 当前用哪块 GPU 渲染 (详见文件头部 niriGpu 定义)
    ngpu = "niri-gpu";
    # 一键清理 NixOS 旧世代 & 垃圾回收 Nix Store
    nclean = "sudo nix-collect-garbage -d";
  };

  # --- 通用命令 ---
  home.packages = [ niriGpu ];

  # --- PATH: 全局只定义一次, 所有 shell 生效 ---
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
}
