#!/usr/bin/env bash

# 开启 Bash 严格模式，提升脚本可靠性
# -e: 遇到错误立即退出
# -u: 使用未定义变量时报错
# -o pipefail: 管道中任何一个命令失败则整个管道判定为失败
set -euo pipefail

# ==========================================
# 默认参数配置
# ==========================================
FLAKE_PATH="."
HOSTNAME="nixos"
# 自动获取 CPU 核心数作为默认并发数, 如果获取失败则回退到 4
MAX_JOBS=$(nproc 2>/dev/null || echo 4)
CORES="0"
TARGET_ROOT="/mnt"

# 默认的 Substituters 和 Keys (使用清华源加速)
DEFAULT_SUBSTITUTERS="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org"
DEFAULT_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

# 附加状态标志
IMPURE=0
SHOW_TRACE=0

# ==========================================
# 帮助文档函数
# ==========================================
usage() {
    cat <<EOF
用法: $(basename "$0") [选项]

高级 NixOS 安装脚本

选项:
  -f, --flake PATH        指定 flake.nix 的路径 (默认: ".")
  -n, --hostname NAME     指定要安装的主机名 (默认: "nixos")
  -j, --max-jobs NUM      指定最大并发构建任务数 (默认: $MAX_JOBS)
  -c, --cores NUM         指定每个任务的 CPU 核心数 (默认: 0，由 Nix 接管)
  -r, --root PATH         指定安装的目标挂载点 (默认: "/mnt")
  -s, --substituters STR  覆盖默认的 substituters
  -k, --trusted-keys STR  覆盖默认的 trusted-public-keys
  --impure                允许构建依赖于系统状态的 flake (在未提交 Git 时非常有用)
  --trace                 开启详细的错误追踪 (调试用)
  -h, --help              显示此帮助信息并退出

示例:
  $(basename "$0") -f /path/to/my/flake -n my-laptop -j 8 --impure
EOF
}

# ==========================================
# 命令行参数解析
# ==========================================
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flake)        FLAKE_PATH="$2"; shift 2 ;;
        -n|--hostname)     HOSTNAME="$2"; shift 2 ;;
        -j|--max-jobs)     MAX_JOBS="$2"; shift 2 ;;
        -c|--cores)        CORES="$2"; shift 2 ;;
        -r|--root)         TARGET_ROOT="$2"; shift 2 ;;
        -s|--substituters) DEFAULT_SUBSTITUTERS="$2"; shift 2 ;;
        -k|--trusted-keys) DEFAULT_KEYS="$2"; shift 2 ;;
        --impure)          IMPURE=1; shift 1 ;;
        --trace)           SHOW_TRACE=1; shift 1 ;;
        -h|--help)         usage; exit 0 ;;
        *) echo "错误: 未知的选项 $1"; usage; exit 1 ;;
    esac
done

# ==========================================
# 构建并执行命令
# ==========================================
FLAKE_URI="${FLAKE_PATH}#${HOSTNAME}"

# 检查是否以 root 权限运行 (nixos-install 需要 root)
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  警告: 此脚本通常需要 root 权限运行 (sudo)."
  echo "正在尝试继续, 如果失败请使用 sudo 重试..."
  echo "---------------------------------------------------"
fi

# 使用 Bash 数组来构建命令，完美避免含有空格的字符串被错误分割
CMD=(nixos-install)
CMD+=(--root "$TARGET_ROOT")
CMD+=(--flake "$FLAKE_URI")
CMD+=(--max-jobs "$MAX_JOBS")
CMD+=(--cores "$CORES")
CMD+=(--option "substituters" "$DEFAULT_SUBSTITUTERS")
CMD+=(--option "trusted-public-keys" "$DEFAULT_KEYS")

# 按需添加附加选项
if [ "$IMPURE" -eq 1 ]; then
    CMD+=(--impure)
fi

if [ "$SHOW_TRACE" -eq 1 ]; then
    CMD+=(--show-trace --print-build-logs)
fi

echo "🚀 即将执行的安装命令:"
echo "${CMD[@]}"
echo "==================================================="

# 执行数组命令
"${CMD[@]}"

echo "✅ 安装流程结束。"
