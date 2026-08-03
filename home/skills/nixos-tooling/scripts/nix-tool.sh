#!/usr/bin/env bash
# nix-tool.sh — 在 NixOS 上快速查找并临时运行 CLI 工具 (nixos-tooling skill 辅助脚本)
# 用法:
#   nix-tool.sh <命令> [参数...]                    # 确保命令可用并执行 (必要时自动建临时环境)
#   nix-tool.sh --search <关键词>                   # 只在 nixpkgs 中搜索
#   nix-tool.sh --attr <attrpath> <命令> [参数...]   # 指定包路径, 建临时环境执行
set -euo pipefail

# --- 模式 1: 仅搜索 ---
if [ "${1:-}" = "--search" ]; then
  nix search nixpkgs "${2:?用法: --search <关键词>}"
  exit 0
fi

# --- 模式 2: 指定包路径 ---
if [ "${1:-}" = "--attr" ]; then
  attr="${2:?用法: --attr <attrpath> <命令> [参数...]}"
  shift 2
  exec nix shell "nixpkgs#${attr}" -c "$@"
fi

# --- 模式 3: 自动流程 ---
cmd="${1:?用法: nix-tool.sh <命令> [参数...]}"
shift || true

# 3.1 系统已安装则直接用
if command -v "$cmd" >/dev/null 2>&1; then
  exec "$cmd" "$@"
fi

# 3.2 在 nixpkgs 中检索候选包 (提取 attrpath 列)
echo "[nix-tool] '$cmd' 未安装, 正在 nixpkgs 中检索..." >&2
mapfile -t hits < <(
  nix search nixpkgs "$cmd" 2>/dev/null |
    sed -n 's/^\* \([^[:space:]]*\).*/\1/p' |
    head -8
) || true

if [ "${#hits[@]}" -eq 0 ]; then
  echo "[nix-tool] 未找到匹配包。可尝试: nix-tool.sh --search <其他关键词>" >&2
  echo "[nix-tool] 提示: 命令名与包名常不一致 (如 rg → ripgrep), 用 --search 换关键词" >&2
  exit 1
fi

# 3.3 唯一命中则自动创建临时环境执行
if [ "${#hits[@]}" -eq 1 ]; then
  echo "[nix-tool] 唯一命中: ${hits[0]}, 创建临时环境..." >&2
  exec nix shell "nixpkgs#${hits[0]}" -c "$cmd" "$@"
fi

# 3.4 多个候选时让调用方 (agent) 用 --attr 指定
echo "[nix-tool] 多个候选包, 请用 --attr 指定 (例: nix-tool.sh --attr ${hits[0]} ${cmd} $*):" >&2
printf '  * %s\n' "${hits[@]}" >&2
exit 1
