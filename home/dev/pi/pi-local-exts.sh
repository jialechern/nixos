#!/bin/sh
# pi 项目级 (--local) 扩展集合管理。
#
# 由 home/dev/pi.nix 的 pi-init / pi-coding / pi-clean 别名调用, 集合定义在
# 该文件的 localBaseExtensions / localCodingExtensions 中。
#
# 用法:
#   pi-local-exts install <pkg>...   把包追加到当前项目的 --local 扩展集合。
#                                    幂等: 已装配的跳过, 不碰其他包。因此依次运行
#                                    多个别名得到的是它们的"并集": 日常项目只跑
#                                    pi-init 保持轻量, 复杂项目再叠加 pi-coding,
#                                    主动用启动耗时换功能。
#   pi-local-exts clean              卸载当前项目全部 --local 扩展, 并清理
#                                    ~/.pi/agent/npm 中不被 settings.json 识别的
#                                    全局残留。这是唯一的"重置"手段。
#   pi-local-exts status             显示当前项目已装配的 --local 扩展。
#
# 包名统一用 jq 的 (.source? // .) 提取, 兼容 "npm:x" 与 { source = ...; } 两种
# packages 写法。
#
# 注: --local 装配要求项目已被 pi 信任, 否则 pi install 会拒绝。
set -eu

settings=".pi/settings.json"

# 读出当前项目 .pi/settings.json 里的包名 (空格分隔)
read_local() {
    if [ -f "$settings" ]; then
        jq -r '.packages[]? | (.source? // .)' "$settings" 2>/dev/null | tr '\n' ' '
    fi
}

# 清理 ~/.pi/agent/npm 中未被 settings.json 声明的依赖。全局扩展由 Nix 声明式
# 管理, 手动 pi install 写入的依赖在 rebuild 后不被 settings.json 识别, 属垃圾文件。
clean_global_leftovers() {
    agent_settings="$HOME/.pi/agent/settings.json"
    agent_manifest="$HOME/.pi/agent/npm/package.json"
    if [ ! -f "$agent_settings" ] || [ ! -f "$agent_manifest" ]; then
        return 0
    fi
    for pkg in $(jq -r '.dependencies | keys[]' "$agent_manifest"); do
        if ! jq -e --arg p "npm:$pkg" \
             '.packages | any((.source? // .) == $p)' "$agent_settings" >/dev/null 2>&1; then
            echo "pi-local-exts: 清理全局残留 $pkg"
            (cd "$HOME/.pi/agent/npm" && npm uninstall "$pkg")
        fi
    done
}

case "${1:-}" in
    install)
        shift
        cur="$(read_local)"
        for p in "$@"; do
            case " $cur " in
                *" $p "*) ;;
                *) echo "pi-local-exts: 安装 $p"; pi install --local "$p" ;;
            esac
        done
        ;;
    clean)
        cur="$(read_local)"
        if [ -z "$cur" ]; then
            echo "pi-local-exts: 当前项目无 --local 扩展"
        else
            for p in $cur; do
                echo "pi-local-exts: 卸载 $p"
                pi uninstall --local "$p"
            done
        fi
        clean_global_leftovers
        ;;
    status)
        cur="$(read_local)"
        if [ -z "$cur" ]; then
            echo "当前项目无 --local 扩展"
        else
            echo "当前项目 --local 扩展:"
            for p in $cur; do echo "  $p"; done
        fi
        ;;
    *)
        echo "用法: pi-local-exts {install <pkg>... | clean | status}" >&2
        exit 2
        ;;
esac
