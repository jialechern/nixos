#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# dotfiles 仓库同步脚本
# 用法：
#   ./sync-dotfiles.sh                 # 默认使用国际源(GitHub), SSH 方式
#   ./sync-dotfiles.sh --source cn     # 使用国内源(Gitee), SSH 方式
#   ./sync-dotfiles.sh --source intl   # 明确使用国际源(GitHub), SSH 方式
#   ./sync-dotfiles.sh --https         # 使用 HTTPS 方式拉取(适用于公开仓库)
# =========================================================

# -----------------------------
# 选择使用的源: intl 或 cn
# 默认值为 intl
# -----------------------------
SOURCE="intl"

# -----------------------------
# 是否使用 HTTPS 方式拉取(默认使用 SSH)
# -----------------------------
USE_HTTPS="false"

# -----------------------------
# dotfiles 根目录
# 这里存放各个 git 仓库
# 你可以按需修改
# -----------------------------
DOTFILES_ROOT="${DOTFILES_ROOT:-/etc/nixos/dotfiles}"

# -----------------------------
# 仓库列表
# 每个仓库包含：
#   名称 | 本地目录名 | 国际源 URL | 国内源 URL | 默认分支
# 你只需要在这里补全你的真实仓库地址
# -----------------------------
REPOS=(
  "nvim|nvim|git@github.com:jialechern/nvim.git|git@gitee.com:cjl-2692367185-qed/nvim.git|main"
  "niri|niri|git@github.com:jialechern/niri.git|git@gitee.com:cjl-2692367185-qed/niri.git|main"
  "alacritty|alacritty|git@github.com:jialechern/alacritty.git|git@gitee.com:cjl-2692367185-qed/alacritty.git|main"
  "keepass|keepassxc|git@github.com:jialechern/keepass.git|git@gitee.com:cjl-2692367185-qed/keepass.git|main"
)

# -----------------------------
# 打印用法说明
# -----------------------------
usage() {
  cat <<'EOF'
用法：
  sync-dotfiles.sh [--source intl|cn] [--root 路径] [--https]

参数：
  --source   选择仓库来源, intl 表示国际源, cn 表示国内源
  --root     dotfiles 根目录, 默认是 /etc/nixos/dotfiles
  --https    使用 HTTPS 方式拉取(公开仓库), 不指定则使用 SSH
  -h, --help 显示帮助

示例：
  sync-dotfiles.sh
  sync-dotfiles.sh --source cn
  sync-dotfiles.sh --https
  sync-dotfiles.sh --root /persist/dotfiles --source intl --https
EOF
}

# -----------------------------
# 解析命令行参数
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --root)
      DOTFILES_ROOT="${2:-}"
      shift 2
      ;;
    --https)
      USE_HTTPS="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      usage
      exit 1
      ;;
  esac
done

# -----------------------------
# 检查 git 是否存在
# -----------------------------
if ! command -v git >/dev/null 2>&1; then
  echo "错误: 未找到 git, 请先安装 git."
  exit 1
fi

# -----------------------------
# 检查源参数是否合法
# -----------------------------
if [[ "$SOURCE" != "intl" && "$SOURCE" != "cn" ]]; then
  echo "错误: --source 只能是 intl 或 cn"
  exit 1
fi

# -----------------------------
# 选择当前要使用的仓库 URL
# -----------------------------
choose_url() {
  local intl_url="$1"
  local cn_url="$2"

  if [[ "$SOURCE" == "cn" ]]; then
    printf '%s\n' "$cn_url"
  else
    printf '%s\n' "$intl_url"
  fi
}

# -----------------------------
# 将 SSH 地址转换为 HTTPS 地址
# git@github.com:user/repo.git  →  https://github.com/user/repo.git
# git@gitee.com:user/repo.git   →  https://gitee.com/user/repo.git
# -----------------------------
ssh_to_https() {
  local ssh_url="$1"

  [[ "$ssh_url" =~ ^git@([^:]+):(.+)$ ]] || {
    echo "错误: 无法解析 SSH 地址格式: ${ssh_url}" >&2
    exit 1
  }

  printf 'https://%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

# -----------------------------
# 同步单个仓库
# 如果目录不存在则 clone
# 如果目录已存在则更新 remote 并 pull
# -----------------------------
sync_repo() {
  local name="$1"
  local dir_name="$2"
  local intl_url="$3"
  local cn_url="$4"
  local branch="$5"

  local repo_dir="${DOTFILES_ROOT}/${dir_name}"
  local url
  url="$(choose_url "$intl_url" "$cn_url")"

  # 如果指定了 --https, 将 SSH 地址转换为 HTTPS 地址
  if [[ "$USE_HTTPS" == "true" ]]; then
    url="$(ssh_to_https "$url")"
  fi

  local protocol
  protocol="$([[ "$USE_HTTPS" == "true" ]] && echo "HTTPS" || echo "SSH")"

  echo "==> 处理仓库: ${name}"
  echo "    目标目录: ${repo_dir}"
  echo "    使用源: ${SOURCE}"
  echo "    协议: ${protocol}"
  echo "    地址: ${url}"

  # 目录不存在时, 直接克隆
  if [[ ! -e "$repo_dir" ]]; then
    mkdir -p "$DOTFILES_ROOT"
    git clone --branch "$branch" "$url" "$repo_dir"
    return 0
  fi

  # 目录存在但不是 git 仓库时, 直接报错
  if [[ ! -d "$repo_dir/.git" ]]; then
    echo "错误: ${repo_dir} 已存在, 但它不是 git 仓库."
    exit 1
  fi

  # 更新远程地址, 保证切换源时不会拉错地址
  git -C "$repo_dir" remote set-url origin "$url"

  # 拉取最新内容
  git -C "$repo_dir" fetch --all --prune

  # 尽量快进合并，避免制造额外提交
  git -C "$repo_dir" pull --ff-only --recurse-submodules
}

# -----------------------------
# 开始同步全部仓库
# -----------------------------
echo "开始同步 dotfiles..."
echo "根目录: ${DOTFILES_ROOT}"
echo "源: ${SOURCE}"
echo "协议: $([[ "$USE_HTTPS" == "true" ]] && echo 'HTTPS' || echo 'SSH')"
echo

for item in "${REPOS[@]}"; do
  IFS='|' read -r name dir_name intl_url cn_url branch <<< "$item"
  sync_repo "$name" "$dir_name" "$intl_url" "$cn_url" "$branch"
  echo
done

echo "全部仓库同步完成."
