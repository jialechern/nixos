# 命令速查与对照 (nix-tool references)

> 本 skill 强制使用现代 CLI。以下为完整速查与旧命令对照。仅当命令选项不确定或需要对照旧写法时读取本文。

## 1. 现代 CLI 与旧命令对照表

| 目的 | ✅ 现代写法 (本 skill 采用) | ❌ 旧写法 (禁用) |
| --- | --- | --- |
| 检索包 | `nix search nixpkgs <关键词>` | `nix-env -qaP` / `nix search` 旧版 |
| 临时环境执行命令 | `nix shell nixpkgs#<pkg> -c <cmd>` | `nix-shell -p <pkg> --run '<cmd>'` |
| 进入临时交互环境 (仅人用; agent 禁止, 见单命令形态) | `nix shell nixpkgs#<pkg>` | `nix-shell -p <pkg>` |
| 直接运行包主程序 | `nix run nixpkgs#<pkg> [-- <args>]` | `nix-shell -p <pkg> --run '<pkg> <args>'` |
| 构建 (调试/出产物) | `nix build [nixpkgs#<pkg>]` | `nix-build` |
| 求值查属性 | `nix eval nixpkgs#<pkg>.version --raw` | `nix-instantiate --eval` |
| 查配置 | `nix config show` | `nix show-config` |
| 垃圾回收 | `nix store gc [--dry-run]` | `nix-collect-garbage` |
| 删 profile 旧世代 | `nix profile wipe-history` (再 `nix store gc`) | `nix-collect-garbage -d` |
| 持久安装 | `nix profile install nixpkgs#<pkg>` (本 skill 不推荐) | `nix-env -iA nixpkgs.<pkg>` |
| 查日志 | `nix log nixpkgs#<pkg>` | `nix-build ... -K` / `nix log` 旧版 |
| 下载 URL 到 store | `nix store prefetch-file <url>` | `nix-prefetch-url` |

> 澄清: `nix-locate` (来自 `nix-index` 包) **不是**被废弃的 `nix-*` 家族, 是独立工具, 可用于"二进制名 → 包名"反查: `nix shell nixpkgs#nix-index -c nix-locate -t x -w <bin>` (需先建索引库 `nix-index`, 成本高, 反查无果时才用)。
>
> 注意: NixOS 系统自动 GC (`nix.gc.automatic`) 内部由系统调用 `nix-collect-garbage`, 这是系统实现细节, 不是本 skill 的教学命令。

## 2. flake 引用语法速查

| 引用 | 含义 | 备注 |
| --- | --- | --- |
| `nixpkgs#<attr>` | registry 中的 `nixpkgs` (unstable) | 若 registry 已被系统配置映射到锁定的同源 nixpkgs (NixOS 常见), 命中缓存零下载 |
| `nixpkgs#<attr>@<version>` | 指定版本 | 版本在 nixpkgs 中不存在会报错 |
| `github:NixOS/nixpkgs/nixos-25.11#<attr>` | 稳定分支 | 引入整棵新 nixpkgs tree, 大陆直连可能被墙 |
| `git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable#<attr>` | TUNA 镜像的 nixpkgs | 国内拉取优先用此前缀替代 `github:` |
| `github:<owner>/<repo>/<ref>#<attr>` 等 | 任意 flake | 仅用户明确指定时使用; 不运行不可信 flake |

## 3. 常用临时参数 (单命令内联)

```bash
# 临时追加镜像 substituter (仅 trusted user 有效, 见 SKILL.md §2)
nix shell --option extra-substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store nixpkgs#<pkg> -c <cmd>

# 临时换主 substituter (覆盖而非追加)
nix shell --option substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store nixpkgs#<pkg> -c <cmd>

# 禁止走二进制缓存 (强制本地编译, 排查缓存问题时用)
nix shell --option substitute false nixpkgs#<pkg> -c <cmd>

# 代理: 客户端单命令注入 (仅影响客户端自身 fetch, 见 SKILL.md §2 分层说明)
# 全量双写注入模型与默认 NO_PROXY 清单见 references/proxy.md
env HTTPS_PROXY=<代理地址> HTTP_PROXY=<代理地址> ALL_PROXY=<代理地址> \
    NO_PROXY=localhost,127.0.0.1,::1 nix shell github:NixOS/nixpkgs#<pkg> -c <cmd>
```

## 4. 常用组合示例

```bash
# 多包 + 管道
nix shell nixpkgs#jq nixpkgs#curl -c bash -c 'curl -s https://api.example.com | jq .'

# nix search 结构化输出 (剥离 legacyPackages.<system>. 前缀 → 短 attrpath)
nix search nixpkgs --json '<关键词>' | jq -r 'keys[]' | sed -E 's/^(legacyPackages|packages)\.[^.]+\.//' | head -20

# 查某包是否已在本机 store (必须 --offline: 不加会触发实际下载, 失去判定意义)
nix path-info --offline nixpkgs#<pkg> 2>/dev/null && echo "已在 store"

# 查看将执行环境包含的路径
nix shell nixpkgs#<pkg> -c bash -c 'echo $PATH'
```
