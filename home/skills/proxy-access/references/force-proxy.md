# 强制程序走已有代理: 工具对比与最小示例 (proxy-access references)

> 适用场景: SKILL.md §2.3 — 目标程序不读取 *_proxy 环境变量。
> 选择顺序 (侵入程度从低到高): 应用自身配置 → proxychains (LD_PRELOAD) → graftcp (ptrace) → 透明代理 (系统级)。

## 1. 决策表

| 场景 | 手段 | 理由 |
| --- | --- | --- |
| 程序自带代理选项 (git/curl/pip/npm/go/cargo/apt…) | **应用自身配置** | 零副作用、最可靠, 首选 |
| 动态链接 C 程序 / 走 libc connect() 的脚本 | **proxychains4** | 单命令、生态成熟 |
| Go 程序 / 静态链接 / setuid / LD_PRELOAD 被禁用 | **graftcp** (仅 Linux) | ptrace 不看链接方式 |
| 全量接管 / 所有进程 | 透明代理 (见 transparent-proxy.md) | 系统级, 需 root |

经验法则: 先问"程序有没有 --proxy/配置项" → 再看"是不是动态链接 C 程序" → 再看"是不是 Go/静态" → 最后才考虑系统级。除非确定, 不要动 iptables。

## 2. 应用自身代理选项 (首选)

| 工具 | 用法 | 说明 |
| --- | --- | --- |
| git | `git -c http.proxy=<地址> -c https.proxy=<地址> <命令>` | 也读 http_proxy/https_proxy/all_proxy env |
| curl | `curl -x <地址> ...`; socks 且需远端解析域名用 `--socks5-hostname` | 也读 http_proxy/https_proxy/all_proxy/no_proxy |
| pip | `pip install --proxy <地址> ...` 或 env `PIP_PROXY` | |
| npm | `npm --proxy=<地址> --https-proxy=<地址> ...` | 也读 HTTP_PROXY/HTTPS_PROXY |
| go | 网络代理读 HTTP_PROXY/HTTPS_PROXY; 模块下载用 `GOPROXY=...` (那是镜像, 两回事) | |
| cargo/apt/dnf 等 | 多数读 HTTP_PROXY/HTTPS_PROXY/ALL_PROXY | |

## 3. proxychains (LD_PRELOAD)

- 上游 proxychains-ng, 可执行文件 `proxychains4`; **命令名随发行版而异** (`proxychains4` Debian 系 / `proxychains` 部分发行版), 先 `command -v proxychains4 || command -v proxychains` 确认。
- 配置查找顺序 (上游): `PROXYCHAINS_CONF_FILE` env 或 `-f` 参数 → `./proxychains.conf` → `~/.proxychains/proxychains.conf` → `/etc/proxychains.conf` (Debian 另加 `/etc/proxychains4.conf`)。**给 agent 的最稳做法: 显式 `-f <临时配置>`**:

```bash
TMP=$(mktemp -d)
printf 'proxy_dns\n[ProxyList]\nsocks5 127.0.0.1 <端口>\n' > "$TMP/pc.conf"   # 或 http 127.0.0.1 <端口>
proxychains4 -f "$TMP/pc.conf" <命令> [参数...]
rm -rf "$TMP"
```

- 协议: SOCKS4a/SOCKS5/HTTP CONNECT, 可混用成链; 仅 TCP。`proxy_dns` 让域名由代理侧解析 (防本地 DNS 泄漏)。
- 局限 (升级判据): 静态链接二进制无效; **Go 二进制通常无效** (绕过 libc connect()); setuid 程序被 glibc 忽略 LD_PRELOAD; macOS SIP 阻止 hook 系统二进制; perl/python 等依赖 C 扩展的程序可能不可靠; nmap/raw socket 类程序无效。
- 打包: nixpkgs `proxychains-ng` (命令 proxychains4) / 旧版 `proxychains`; apt `proxychains4`; dnf/pacman/brew `proxychains-ng`。

## 4. graftcp (ptrace, 覆盖 Go/静态)

- 机制: fork 目标进程 + ptrace 拦截 connect(), 改写目的地址到本地监听器, 再经 SOCKS5/HTTP 转发。不依赖 LD_PRELOAD → 对 Go/静态二进制有效。仅 Linux。
- 用法 (新版单命令; 老版需 graftcp-local 先行):

```bash
cat > "$TMP/graftcp.conf" <<EOF
socks5 = 127.0.0.1:<端口>
# 或 http_proxy = 127.0.0.1:<端口>
EOF
graftcp --config "$TMP/graftcp.conf" <命令> [参数...]
```

- 打包现状: **nixpkgs 无 graftcp** (本地 `nix search` 已核验); AUR 有; 其他发行版多需自编译 (Go 项目, 构建简单)。仅在 proxychains 明确无效时值得引入; 获取方式: 官方源码 `go build` 到临时目录, 或自建临时 flake。
- 局限: ptrace 有性能损耗; 部分程序检测被 ptrace 后会拒绝运行。

## 5. 其他工具 (定位区分, 一般不选)

| 工具 | 定位 | 结论 |
| --- | --- | --- |
| tsocks | 老一代 LD_PRELOAD, 仅 SOCKS, DNS 处理差 | Debian 已 orphaned, **弃用** |
| redsocks | iptables REDIRECT → SOCKS/HTTP | 系统级透明代理实现, 需 root; 原作者声明不活跃 (有 redsocks2 fork)。与"请用户开全局透明代理"等价, agent 不自建 |
| gost | 隧道/协议转换/代理链 (`gost -L http://:8080 -F socks5://...`) | 不是"强制器", 需配合应用配置; 仅在需要协议转换时用 (nixpkgs `gost`; 注意 unstable=v3 与稳定分支=v2 的 CLI 差异) |
| socat | 固定目标 1:1 隧道 (`socat TCP-LISTEN:22222,reuseaddr,fork SOCKS4A:127.0.0.1:host:22,socksport=<端口>`) | 只适合"把某一个固定地址经代理暴露成本地端口" |

## 6. 每级失败判据 (写给 agent)

- 应用配置: 程序无代理选项 → 下一级。
- proxychains: 无效时先确认配置指向的端口协议正确 (`curl -x` 验证), 再判"静态/Go" (`file <二进制>` 看 dynamically linked; Go 二进制另有特征) → 升级。
- graftcp: 仅 Linux 且获取成本高 → 先看透明代理路径是否更快 (用户已有全局透明代理时直接走 SKILL.md §2.4)。
