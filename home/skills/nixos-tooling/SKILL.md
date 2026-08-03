---
name: nixos-tooling
description: "在 NixOS 上查找并快速获取/运行 CLI 工具的标准流程: 先确认系统是否已安装, 再在 nixpkgs 中检索包名 (attrpath), 然后通过 nix shell / nix run 创建临时环境运行而不改动系统配置, 需要持久安装时提醒用户修改 home-manager 配置。当需要执行某个命令但 command -v 找不到该工具、需要特定版本的软件、想临时试用软件而不污染系统, 或因国内网络无法访问软件/服务需要走代理 (proxychains4 或 HTTP_PROXY 环境变量, 127.0.0.1:20172) 时使用本 skill。"
license: MIT
compatibility: NixOS (flakes 已启用)
metadata:
  audience: ai-agents
---

# NixOS 工具查找与临时环境 (nixos-tooling)

## 核心理念

NixOS 是不可变系统, 系统配置 (flake) 不应被临时工具需求改动。
任何临时工具的获取都应通过 Nix 的**临时环境**机制完成, 用完即弃、零副作用。

**优先级**: 已安装工具直接使用 → nixpkgs 检索 → `nix shell` / `nix run` 临时环境
→ 持久安装 (仅用户确认后)

## 操作流程

### 1. 先确认工具是否已存在

```bash
command -v <工具名>
```

存在 → 直接用, 跳过后续步骤。

### 2. 在 nixpkgs 中查找软件包

```bash
nix search nixpkgs <关键词>
```

- 关键词支持正则: `nix search nixpkgs '^yq$'`
- 结果第一列是 **attrpath** (真正的包名), 例如 `python312Packages.pyyaml`
- 命令名与包名常不一致 (如 `rg` → 包名 `ripgrep`), 换关键词多搜几次
- 也可用网页版: https://search.nixos.org/packages

### 3. 用临时环境获取并运行 (推荐)

进入临时交互 shell:

```bash
nix shell nixpkgs#ripgrep
```

不进入交互, 直接执行命令:

```bash
nix shell nixpkgs#ripgrep -c rg --help
```

一次携带多个包:

```bash
nix shell nixpkgs#yq nixpkgs#jq -c yq '.a' data.yaml
```

直接运行可执行包 (不进入 shell):

```bash
nix run nixpkgs#lazygit
```

指定版本 (`pkg@version`):

```bash
nix shell nixpkgs#ripgrep@14.1.0 -c rg --version
```

使用稳定分支的旧版本 (默认 registry 的 `nixpkgs` 是 unstable):

```bash
nix shell github:NixOS/nixpkgs/nixos-25.11#ripgrep -c rg --version
```

国内镜像 (TUNA, 与本机 flake 同源, 拉取更快):

```bash
nix shell git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable#ripgrep -c rg --version
```

### 4. 需要持久安装时

- **不要**擅自修改 /etc/nixos 或执行 `nix-env -iA`
- 告知用户: 需要永久使用的工具应声明在 home-manager 或系统配置中, 然后
  `sudo nixos-rebuild switch --flake /etc/nixos#<主机名>` 生效
- 仅当用户明确同意时, 可用 `nix profile install nixpkgs#<pkg>` 临时持久化
  (不推荐作为主方案)

## 网络受限处理 (国内网络)

当软件/服务因国内网络无法正常访问时 (症状: 连接超时、连接被重置、TLS
握手失败、或已知站点请求失败), 按以下顺序处理:

### 0. 判断是否真的需要代理

- 中国直连可达的服务**不需要**代理: DeepSeek、火山方舟 (Volcengine
  Ark)、百度系、TUNA/USTC 镜像、rsproxy 等
- 需要代理的典型目标: Google、GitHub、npm 官方源、PyPI 官方源、部分海外 API
- 有国内镜像可用的服务优先用镜像 (如 npm 用 npmmirror、Python 用 TUNA pypi 源),
  其次才走代理
- 快速验证代理本身是否可用:

```bash
curl -x http://127.0.0.1:20172 -sI -m 8 https://www.google.com
```

### 1. 方案 A — 环境变量 (推荐, 适用于走 HTTP(S) 协议的工具)

```bash
export HTTPS_PROXY=http://127.0.0.1:20172
export HTTP_PROXY=http://127.0.0.1:20172
export ALL_PROXY=http://127.0.0.1:20172
export NO_PROXY=localhost,127.0.0.1,::1
```

- 单次命令不污染环境: `env HTTPS_PROXY=... HTTP_PROXY=... <命令>`
- 部分工具自带代理配置, 不要只依赖通用变量:
  - git: `git -c http.proxy=http://127.0.0.1:20172 <命令>`
  - npm:
    `npm --proxy=http://127.0.0.1:20172 --https-proxy=http://127.0.0.1:20172 <命令>`
  - pip: `pip install --proxy=http://127.0.0.1:20172 ...`
  - curl/wget: `-x http://127.0.0.1:20172`

### 2. 方案 B — proxychains4 (透明转发, 适用于不读取代理变量的程序)

```bash
proxychains4 <命令>
```

- 系统已装 proxychains-ng, 配置由 home-manager 声明式部署在
  `~/.proxychains/proxychains.conf` (指向 127.0.0.1:20172)
- 若报找不到配置/连到错误端口: 检查该文件是否存在, 不存在则退回方案 A
- 通过 LD_PRELOAD 实现, 少数程序会检测或绕过, 对这类程序无效 → 退回方案 A

### 3. 代理不可用时

- 检查 v2raya 是否在监听: `ss -tlnp | grep 20172`
- 代理未运行时, 向用户报告并停止重试, 不要反复等待超时
- 注: nix-daemon 的拉取/构建同样依赖该代理 (见
  /etc/nixos/modules/nix-config.nix), 代理挂掉时构建失败属预期现象

## 排查与注意事项

- **包名歧义**: 同名多包时按场景选择 (如 `git` 与 `gitAndTools`; `nix search`
  结果多时用正则精确匹配)
- **构建/网络失败**: 若因国内网络受限导致拉取/构建失败, 按上文
  「网络受限处理」章节排查 (nix-daemon 同样依赖 127.0.0.1:20172 代理)
- **二进制缓存**: 本机已配置 TUNA/USTC substituters,
  大多数包直接下载、无需本地编译
- `nix shell` 退出即还原, 不会在系统留下任何痕迹

## 辅助脚本

`scripts/nix-tool.sh` 封装了流程 1~3 步 (优先用脚本, 失败再手动按上面步骤排查):

```bash
bash scripts/nix-tool.sh <命令> [参数...]                    # 自动: 已装则直接用, 否则建临时环境执行
bash scripts/nix-tool.sh --search <关键词>                   # 只在 nixpkgs 中搜索
bash scripts/nix-tool.sh --attr <attrpath> <命令> [参数...]   # 指定包路径, 建临时环境执行
```
