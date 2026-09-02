---
name: nix-tool
description: "在有 nix 包管理器 (NixOS 或装有 nix) 的系统中临时获取并运行 CLI 工具的流程: 先判定环境与网络/镜像可用性, 再用 nix search 检索 nixpkgs, 通过 nix run / nix shell 构建一次性临时环境执行命令, 用完即弃、不改动系统配置; 附带 FHS/未打包二进制、网络受限、收尾清理等特殊情况的处理。当 agent 意识到需要某个软件解决用户的问题或子任务却发现 command -v 找不到它、用户说 '临时用一下/别安装/不想污染系统/快速跑个 X/一次性工具'、命令报 command not found 且该工具可由 nixpkgs 提供、或需要不落盘地试用某 CLI 时务必使用本 skill。纯 nix 概念问答、明确要求永久安装或修改系统配置、用户已指定系统包管理器的场景不使用本 skill。"
license: MIT
compatibility: NixOS (daemon 模式) / 装有 nix ≥2.4 且启用 flakes 的系统
metadata:
  audience: ai-agents
---

# Nix 临时工具获取与运行 (nix-tool)

## 速览 (TL;DR)

**大多数场景只需三步, 其余章节按需再读:**

```bash
command -v <工具名> || true        # ① 已安装 → 直接使用, 结束
nix search nixpkgs --json '<关键词>' 2>/dev/null \
  | jq -r 'keys[]' | sed -E 's/^(legacyPackages|packages)\.[^.]+\.//'   # ② 查包名 (剥前缀)
nix shell nixpkgs#<包> -c <命令> [参数...]   # ③ 临时环境跑单条命令, 用完即弃
```

- **只写单命令**, 不进入交互 shell; **不跨调用 export**; 只用现代 CLI (`nix shell`/`run`/`search`)。
- 失败 → 先查 `references/troubleshooting.md` (§5.4); 网络失败 → §2 (拉包层) / §5.2 (应用层)。
- 未打包二进制 → §5.1 (steam-run); 需收尾 → §6; 边界 → §7。

## 理念

- 声明式系统 (NixOS 等) 不应因临时需求被改动。任何临时工具都通过 Nix 的一次性环境机制获取:**用完即弃、零配置副作用**。
- 优先级固定: 已安装工具直接用 → nixpkgs 检索 → `nix run` / `nix shell` 临时环境 → 持久化 (仅用户确认, 且走声明式, 见 §6)。
- 本 skill 只保证「临时、不落配置」。持久安装、代理治理是其它职责, 不在本流程内展开 (见 §7 边界)。
- 安全边界: `nix run`/`nix shell` 即执行第三方代码。只从 nixpkgs 与用户明确指定的 flake 取包; 不运行不可信 flake。
- 命令规范 (强制): 全篇只用现代 CLI `nix <subcommand> [options] args` (`nix search`/`shell`/`run`/`store gc`/`eval`/`config show`/`profile`), **禁用** `nix-shell`/`nix-env`/`nix-build`/`nix-collect-garbage`/`nix-instantiate` 等旧式命令。对照表见 `references/commands.md`。

## 0. 前置: 目标软件是否真的缺失

```bash
command -v <工具名> && <工具名> --version   # 已存在 → 直接使用 (个别工具无 --version 也没关系), 本 skill 到此结束
```

已装工具直接用于任务, 不要绕道 nix 再取一份。

## 1. 环境识别 (进入流程必做)

按序判定, 每个分支给出判定命令:

| # | 判定 | 命令 | 结果 |
| --- | --- | --- | --- |
| 1.1 | 是否 NixOS | `grep -q '^ID=nixos' /etc/os-release && echo NixOS` | 输出 NixOS → 继续 (daemon 模式) |
| 1.2 | 是否装有 nix | `command -v nix && nix --version`; `nix config show \| grep -i experimental-features` 应含 `flakes nix-command` | 有 → 继续; 再 `pgrep -x nix-daemon` 判断 daemon/单用户 (见 §5.3) |
| 1.3 | 可装 nix 但未装 | 询问用户是否安装 (官方 installer 或系统包管理器; 大陆网络受限时先解决访问) | 同意 → 安装后需**新 shell/重新登录**使 PATH 生效, 重新执行 §1; 拒绝 → 见 1.5 |
| 1.4 | 系统不支持 nix | 告知原因 | 见 1.5 |
| 1.5 | **退出交接** | 明确告知用户: 本 skill 只服务 nix 环境; 改由其系统包管理器方案执行。给出已确认的结论, 不再反复尝试 nix |

## 2. 网络与下载源适配 (自动短路, 失败才问)

**默认假设可用, 先自动检测, 不要一进来就询问用户配置镜像/代理。**

1. 读当前 substituters (镜像) 配置:

   ```bash
   nix config show | grep -i substitut    # 或读 /etc/nix/nix.conf (NixOS) / ~/.config/nix/nix.conf
   ```

   中国大陆常见镜像示例: `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org/`。只作参考, 以检测到的实际配置为准。
2. 镜像可达性快检 (对配置中的每个 substituter 逐个执行):

   ```bash
   curl -sI -m 5 <substituter-url>/nix-cache-info | head -1   # 返回 200 即可用
   ```

3. 已配且可达 → **跳过本节**。
4. 只有实际出现 eval/下载失败 (超时、重置、TLS 失败) 时才向用户确认, 提供按序选项:
   - **a. 命令行临时加镜像** (仅当你是 trusted user 才有效, 见下):

     ```bash
     nix shell --option extra-substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store nixpkgs#<pkg> -c <cmd>
     ```

   - **b. 临时换 flake 源** (针对 registry 源本身不可达): 用镜像 git 前缀替代 `github:` 引用 (如 `git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable#<attr>`), 详见 `references/commands.md`。
   - **c. 走系统代理**: 按 §5.2 探测并注入已有代理。
   无论选哪项, **执行后告知用户这只是临时参数**, 建议持久化到其系统 nix 配置 (NixOS 上通常是管理 substituters/daemon 代理的模块), 但不擅自修改。

**分层机制 (必须理解, 否则会误判)**: 多用户 daemon 模式下, 二进制下载由 `nix-daemon` 完成, 只走 daemon 侧的 substituters 与代理环境 (NixOS 可在 nix-daemon 服务上注入代理); **客户端 export 的代理变量不影响下载**, 只影响客户端自身操作 (如 fetch flake 输入)。客户端 `--option extra-substituters` 需你属于 `trusted-users` (查 `nix config show` 中 `trusted-users`, 如 `@wheel`), 否则被 daemon 静默忽略 → 改走方案 b 或让用户以 root/受信用户执行。

## 3. 在 nixpkgs 中检索包 (命令名 → attrpath)

```bash
# 结构化: 剥离 legacyPackages.<system>. 前缀后得到可直接使用的短 attrpath (推荐给 agent 解析)
# 2>/dev/null 抑制全量求值进度输出 (12 万+ 行); 输出为空说明命令失败, 去掉 2>/dev/null 重跑看报错
nix search nixpkgs --json '<关键词>' 2>/dev/null | jq -r 'keys[]' | sed -E 's/^(legacyPackages|packages)\.[^.]+\.//'

# 人读: 支持正则, 第一列是完整属性路径, 也可直接用于 nixpkgs#<完整路径>
nix search nixpkgs '^yq$' 2>/dev/null
```

- 实测: `nix search --json` 的 keys 形如 `legacyPackages.x86_64-linux.yq`, 剥前缀后得短名 `yq`; 完整路径同样可直接拼 `nixpkgs#legacyPackages.x86_64-linux.yq` 使用, 二者等价。
- **命令名 ≠ 包名**: 想用 `rg` 要搜 `ripgrep`; 换关键词多搜几次。
- 反查 (知道二进制名、不知包名): `nix-locate -t x -w <bin>` — 注意 `nix-locate` 是 `nix-index` 包的工具 (非被废弃的 `nix-*` 家族), 需要其数据库, 首次成本高, 仅当正查无果时使用。
- 网页备选: <https://search.nixos.org/packages>
- 不确定时先 search, 不要猜 attrpath。

## 4. 构建临时环境并运行 (核心流程)

> **单命令形态**: agent 的每次 bash 调用是独立短命进程, 不保留 shell 状态。一律写成"一条命令跑完即终", 不要"进入交互 shell 再操作"。

```bash
# 直接运行包的 mainProgram
nix run nixpkgs#<pkg> [-- <参数...>]

# 临时环境内执行单条命令 (最常用)
nix shell nixpkgs#<pkg> -c <cmd> [参数...]

# 一次携带多个包
nix shell nixpkgs#jq nixpkgs#yq -c yq '.a' data.yaml
```

- **命名规则**: 裸 attrpath (如 `nixpkgs#ripgrep`) 使用 registry 的 `nixpkgs`。若 registry 已被系统配置映射到锁定的同源 nixpkgs (NixOS 常见), 缓存命中即零下载。完整 flake 引用 (含 `#`/`:` 者) 原样透传:

  ```bash
  nix shell github:NixOS/nixpkgs/nixos-25.11#ripgrep -c rg --version     # 指定稳定分支
  nix shell git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable#ripgrep -c rg --version   # 大陆走镜像拉取
  ```

- **指定版本**: `nix shell nixpkgs#<pkg>@<版本号> -c <cmd>` — 版本必须在当前 nixpkgs 中存在 (先用 `nix eval nixpkgs#<pkg>.version --raw` 确认, 照抄网上的旧版本号会报错)
- **成本提示**: 显式指定其它分支/仓库会引入**整棵新 nixpkgs tree** — 首次 fetch+eval 可达数百 MB、数分钟; 大陆直连 `github:` 引用常被墙, 优先镜像 `git+https` 前缀或先处理 §2。
- **首次运行耗时可观** (eval + 下载 30s ~ 数分钟属正常): 不要立即判定超时; 大闭包可在后台运行, 完成后再取结果。
- `nix run` 报 mainProgram 缺失/多候选时, 改用 `nix shell nixpkgs#<pkg> -c <pkg>`。
- **长驻/服务类程序**: 必须后台化, 否则占死调用:

  ```bash
  nix shell nixpkgs#tmux -c tmux new -d -s <会话名> 'nix run nixpkgs#<server>' ; sleep 2
  nix shell nixpkgs#tmux -c tmux ls            # 确认存活
  nix shell nixpkgs#tmux -c tmux kill-session -t <会话名>   # 按名清理; 禁用 kill-server (会误杀用户全部会话)
  ```

- **交互式 TUI 程序** (lazygit 等): agent 无法交互 → 优先找非交互 flag; 没有则明示用户需自己在终端运行。

## 5. 特殊情况

### 5.1 FHS 环境需求 (未打包二进制 / AppImage) — 先临时, 后声明式

程序报错形如 `no such file or directory`、缺 `/lib` 下的库、段错误, 且是未打包预编译二进制 → 需要 FHS 兼容环境:

```bash
# 临时方案 (不修改任何配置, 纯 nixpkgs 包):
nix shell nixpkgs#steam-run -c steam-run <未打包二进制> [参数...]      # 任意程序套 FHS
nix shell nixpkgs#appimage-run -c appimage-run <xxx.AppImage>          # AppImage
```

- 若系统已有现成的 FHS 环境命令 (如用户声明式的 `buildFHSEnv` wrapper), 优先直接使用。
- 临时方案库仍缺失 → 记录缺什么 (报错会列出), 询问用户是否转声明式。
- **声明式兜底** (用户确认长期使用): 用 `pkgs.buildFHSEnv` 在配置中声明一个 FHS 环境 — 核心方法 (`targetPkgs` 放命令、`multiPkgs` 放库) 与最小模板见 `references/fhs-env.md`。这是持久化路径, 归入 §6 的转持久分支, 不在临时流程内执行。

### 5.2 程序自身的网络问题 (应用层)

> **定位: 最轻量处理**。多数场景一两步 env 注入即可解决, 不要一遇到网络失败就切换到完整代理流程 (跨 skill 有额外开销)。仅在下方轻量方案全部失败后才升级。

- 先分清是哪一层失败:
  - **nix 拉包/构建失败** → 走 §2 (daemon 镜像/代理层)。
  - **包内程序访问外网失败** (如 curl github 超时) → 本节。
- **探测本机已有代理** (简短按序, 不要一上来就问用户):
  1. 现有代理环境变量: `env | grep -i proxy`
  2. 常见代理客户端的默认监听端口 (v2raya/clash/sing-box 等, 表见 `references/proxy.md`): `ss -tlnp | grep -E ':<候选端口>\b'`
  3. 仍未确认 → 询问用户
- **注入 (核心纪律)**: 单命令内联、**不跨调用 export** (bash 调用间不保留环境), 全量设置 (大写+小写双写兼容不同程序) 并带上 NO_PROXY 防回环:

  ```bash
  env HTTP_PROXY=<代理地址> HTTPS_PROXY=<代理地址> ALL_PROXY=<代理地址> \
      http_proxy=<代理地址> https_proxy=<代理地址> all_proxy=<代理地址> \
      NO_PROXY=localhost,127.0.0.1,::1,.local no_proxy=localhost,127.0.0.1,::1,.local \
      <cmd>
  ```

  代理地址形如 `http://127.0.0.1:<端口>` 或 `socks5://127.0.0.1:<端口>`; 带用户名密码的地址含 `@`/`#` 等字符时用引号包裹。完整注入模型与默认 NO_PROXY 清单见 `references/proxy.md`。
- **程序不读代理变量时**: 若系统已安装 proxychains (命令名可能是 `proxychains` 或 `proxychains4`, 随发行版/包而异, 先 `command -v` 确认), 且其配置指向代理端口, 可用它强制代理 (仅动态链接程序 + TCP 有效)。未安装则不必为此获取, 直接走下方升级路径 — 详见 references/proxy.md §3。
- **验证**: `curl -x <代理地址> -sI -m 8 https://www.google.com | head -1` 返回 200 即通 (HTTP/1.1 或 HTTP/2 均可); 对每个候选端口可分别用 `http://` 与 `socks5://` 前缀试探协议类型。
- 中国直连可达的服务 (DeepSeek、TUNA/USTC、rsproxy 等) 不需要代理。
- **失败升级 (每级只试一次, 不要无限折腾)**: env 注入 (及 proxychains, 若可用) 仍失败时 (常见原因: 程序不读 `*_proxy` 变量、静态链接、代理仅支持特定协议/未运行), 按序升级:
  1. 换完整的网络代理类 skill (若已配置) — 由它做端口/协议深度探测、无代理时临时构建客户端等, 本 skill 不做系统级配置修改;
  2. **兜底终止**: 仍无法连通时, 明确告知用户「因网络受限 (代理不可用或不适用) 该步骤无法完成」, 列出已尝试的方案, 停止重试 — 不要让任务卡死在网络重试上。

### 5.3 单用户 nix 模式 (非 NixOS daemon) 的差异

- substituters 读 `~/.config/nix/nix.conf` 或 `/etc/nix/nix.conf`; 没有 daemon 层, **客户端 env 代理对下载有效** (§2 的分层说明不适用)。
- 无系统级自动 GC 兜底 → §6 的清理询问应主动提出。

### 5.4 其余失败 → 先查 `references/troubleshooting.md` 的错误分类表, 再手动排查

## 6. 收尾 (条件式轻量清理)

任务结束、临时工具不再需要时:

1. **汇报** (一两句): 用了哪个包/来源、是否改动过系统 (通常无)、复现命令是什么。
2. **检测是否有系统自动 GC 兜底**:

   ```bash
   # systemd 系统 (含 NixOS, 对应配置 nix.gc.automatic):
   systemctl list-timers --all 2>/dev/null | grep -i nix-gc || true
   # 无 systemd 或未命中 → 视为"无自动 GC", 走第 4 步
   ```

3. **有自动 GC** → 告知用户: 临时包留在 `/nix/store`, 无引用后由自动 GC 回收, **默认不处理** (同一 nixpkgs 版本内复用会命中缓存, 主动 GC 反而造成重复下载)。
4. **无自动 GC** → 询问用户是否立即释放磁盘:

   ```bash
   nix store gc --dry-run     # 先预览将删除的垃圾
   nix store gc               # 确认后执行
   ```

   > `nix store gc` 是 `nix-collect-garbage` 的现代等价; 两者都只删无人引用的 store 路径。
5. **用户想长期保留该工具** → 转持久, 但**不推荐 `nix profile install`** (会创建独立 gc root, 与声明式配置分叉)。建议: 提示用户在 nix 配置中声明 (NixOS: home-manager `home.packages` 或系统 `environment.systemPackages`), 经用户同意后由其执行系统重建 (`sudo nixos-rebuild switch`)。被配置引用的包不会被 GC。

## 7. 边界与交接

- 本 skill 结束时如产生持久化需求, 只**报告建议与具体修改位置**, 不擅自修改系统 nix 配置、不执行 rebuild、不 `nix profile install`。
- 系统代理的完整探测/临时构建部署流程 → 网络代理类 skill (若有)。
- 换软件镜像源 (npm/pip/rust) → 不属本 skill (本 skill 只处理 nix 下载链路的源)。

## References (按需读取, 不预先加载)

- `references/commands.md` — 现代 CLI 速查、旧命令对照表、flake 引用与临时参数语法。遇到命令选项不确定、或需要对照旧写法时读取。
- `references/proxy.md` — 代理注入模型、常见代理客户端默认端口表、proxychains 兜底与协议验证。§5.2 需要给程序走代理时读取。
- `references/fhs-env.md` — `buildFHSEnv` 声明式 FHS 环境模板与 targetPkgs/multiPkgs 规则。§5.1 临时 FHS 方案仍缺库、需转声明式时读取。
- `references/troubleshooting.md` — 错误现象 → 原因 → 处置 分类表。nix 命令失败时先查此表再排查。
