---
name: proxy-access
description: "在网络受限 (如中国大陆) 环境中为 agent 执行的命令建立网络通路: 先判断任务是否真的需要代理 (本地网络排查、pip/npm/Go/Rust/HF 等换镜像源替代优先), 再探测本机已有代理 (环境变量/端口扫描/客户端 API/询问用户), 优先环境变量单命令注入 (全量大小写双写 + NO_PROXY 防回环, 退出无痕), 程序不读变量时按 proxychains → graftcp → 透明代理逐级强制; 无本地代理但有服务器时用包管理器临时拉起 sing-box/mihomo 客户端 (配置与凭证放临时目录, 用完即删), 无服务器时对公开免费代理做安全评估 (默认禁用)。当命令出现网络超时/连接被重置/connection refused/TLS 失败、需访问境外被墙服务、用户说 '走代理/需要代理/翻墙' 时使用本 skill。agent 自身与模型 API 的连接问题、常驻代理服务配置、单纯换镜像源且无需代理的场景不使用本 skill。"
license: MIT
compatibility: Linux (macOS/Windows 仅部分命令可用; NixOS 可配合 nix-tool skill 临时获取工具)
metadata:
  audience: ai-agents
---

# 网络代理探测与使用 (proxy-access)

## 速览 (TL;DR)

网络失败时的决策链 — 每步失败才进下一步, 每级手段只试一次:

```bash
# ① 判断是否真需要代理: 先排除本地故障、查换源替代 (§1); 不需要 → 明确告知并退出
curl -s --noproxy '*' -m 8 -o /dev/null -w '%{http_code}\n' <目标URL>   # 2xx/3xx=可达; 000=不可达

# ② 探测本机已有代理 (§2.0): env → 端口 → 客户端 API → 问用户
env | grep -i proxy; ss -tlnp 2>/dev/null | grep -E ':(20172|20171|20170|7890|7891|9090|2080)\b'

# ③ 最轻量使用: 环境变量单命令注入 (§2.2), 成功即完成任务
env HTTP_PROXY=http://127.0.0.1:<端口> HTTPS_PROXY=http://127.0.0.1:<端口> ALL_PROXY=http://127.0.0.1:<端口> \
    http_proxy=http://127.0.0.1:<端口> https_proxy=http://127.0.0.1:<端口> all_proxy=http://127.0.0.1:<端口> \
    NO_PROXY=localhost,127.0.0.1,::1,.local,.lan,192.168.0.0/16,10.0.0.0/8 \
    no_proxy=localhost,127.0.0.1,::1,.local,.lan,192.168.0.0/16,10.0.0.0/8 \
    <命令> [参数...]

# ④ 程序不读变量 → proxychains/graftcp 强制 (§2.3) → 透明代理 (§2.4) → 兜底报告 (§5)
# ⑤ 无本地代理 → 有服务器则临时拉起客户端 (§3); 无服务器 → 公开代理安全评估 (§4, 默认禁用)
```

- 单命令作用域, **不跨调用 export**; 临时组件 (客户端进程/配置) 用完即删 (§6)。
- **绝大多数场景止步于 ②③ 两步**; §2.1 起的章节与 references 仅在对应步骤失败时才读, 不要预读。
- 细节按需查 references: 客户端模板 → `clients.md`; 透明代理检测 → `transparent-proxy.md`; 强制工具 → `force-proxy.md`; 换源/安全评估 → `mirrors.md`。

## 理念

- **单一职责**: 只负责"网络层代理"的决策、探测、使用与临时构建。换镜像源在本 skill 中只是"替代方案"决策分支 (§1.2); 持久代理服务与透明代理全局开关由用户完成; agent 自身 (与模型 API) 的连接受 harness 管理。
- **最轻量优先**: 环境变量注入 (无残留、无需 root) > 用户态强制 (proxychains/graftcp) > 透明代理 (系统级, 只复用不搭建)。
- **临时性**: 本 skill 拉起的客户端进程、配置、下载一律放临时目录, 用完即删; 不修改系统配置。
- **安全边界**: 公开免费代理默认视为不可信中间盒, 凭证流量一律禁走 (§4); 代理配置含凭证, 注意文件权限与清理。
- **分层认知**: 普通代理 (HTTP/SOCKS 端口) 属应用层, 可精确到单命令; 透明代理属内核层, 全局生效。nix 多用户 daemon 的下载走 daemon 侧配置, 客户端 export 的变量不影响它 (见 nix-tool skill §2)。

## 0. 触发与边界

**使用本 skill**: 命令报网络超时/连接重置/connection refused/TLS 握手失败且疑似被墙; 用户说"走代理/需要代理/翻墙/科学上网"; 下载境外资源失败。

**不使用本 skill**:

- agent 自身与模型 API 的连接问题 → harness 配置层, 不在命令级解决;
- 配置/部署常驻代理服务 (系统服务、声明式配置、开机自启) → 只给建议不执行;
- 用户明确只要换镜像源且不涉代理 → 直接换源, 不走本 skill 完整流程;
- 已确认是本地网络故障 (网卡/DNS/网关) → 按 §1.1 报告, 不属于代理问题。

## 1. 判断是否真的需要代理

### 1.1 本地网络排查 (先排除"不是代理问题")

按序快速检查, 定位失败点在哪一层:

| 检查 | 命令 | 判定 |
| --- | --- | --- |
| 目标可达性 | `curl -s --noproxy '*' -m 8 -o /dev/null -w '%{http_code}' <目标URL>` | 2xx/3xx → 直连可达, 无需代理 (重跑原命令复核); 000 → 继续排查 |
| DNS 解析 | `getent ahostsv4 <域名>` | 无结果 → 本地 DNS 服务故障 |
| DNS 劫持/污染 | 解析结果是否 198.18.x.x (fake-ip) 或明显错误 IP | 198.18.x.x → 本机已有透明代理 (记下, 转 §2.1 复用); 明显错误 IP → DNS 被污染, 记入"需要代理"旁证 |
| 网关可达 | `ip route` + `ping -c 2 -W 2 <网关IP>` | 网关不通 → 本地网络断, 非代理问题 |
| 失败层级 | `curl -v -m 8 <URL>` 看卡在 DNS/TCP 连接/TLS 握手哪一步 | TCP 通但 TLS 失败 → 疑似干扰/被墙, 指向需要代理; DNS 失败 → 先修 DNS |

- 判定为本地故障 → 明确告知 (故障点 + 证据) 并退出 — 代理解决不了本地断网。
- 直连可达 → 不需要代理, 用直连完成任务并退出。

### 1.2 替代方案检查 (换源优于代理)

判定规则: **公开 + 版本化 + 可缓存 + 只读 → 换镜像源; API / 认证 / 私有 / 推送 / 登录 / 订阅 → 需要代理**。

按失败场景查快速表 (完整命令与现状见 `references/mirrors.md`):

| 失败场景 | 首选替代 (临时, 不改持久配置) | 仍需代理? |
| --- | --- | --- |
| pip install 慢/超时 | `pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <pkg>` | 否 |
| npm install 慢/超时 | `npm install --registry=https://registry.npmmirror.com` | 否 |
| go install 慢/超时 | `GOPROXY=https://goproxy.cn,direct go install ...` | 否 |
| rustup/cargo 慢 | `RUSTUP_DIST_SERVER=https://rsproxy.cn ...` (cargo 无单行 env, 详见 mirrors.md) | 否 |
| Maven 依赖慢 | `mvn -s /tmp/aliyun-settings.xml ...` | 否 |
| Hugging Face 下载慢 | `HF_ENDPOINT=https://hf-mirror.com huggingface-cli download ...` | 否 |
| docker pull 慢 | DaoCloud 前缀 (公共镜像已大面积失效, 探测后用, 不稳) | 部分 |
| GitHub Release/raw 下载慢 | ghproxy 类前缀 + **下载后校验哈希**, 禁带 token | 部分 |
| API 端点 / 私有仓库 / push / 登录 / 订阅更新 / Google 服务 | 无镜像替代 | **是** |

- 镜像可解决 → 用临时参数换源执行, 向用户说明这是临时方案, 退出本 skill。
- 镜像覆盖不了 → 记下原因, 继续 §2。

### 1.3 决策输出

- 无需代理: 在上下文中明确说明判断依据, 退出。
- 需要代理: 明确一句"为什么需要代理", 继续 §2。

## 2. 使用已有本地代理

### 2.0 探测本地代理

按序自动探测, 全部落空才询问用户; 每个候选都要做协议判定:

1. **环境变量**: `env | grep -i proxy` — 注意可能是意外注入 (某工具默认写入), 记录后实测验证, 不可盲信。
2. **常见客户端默认端口** (仅候选, 以实际监听为准):

   ```bash
   ss -tlnp 2>/dev/null | grep -E ':(20170|20171|20172|2017|7890|7891|9090|2080)\b'
   ```

   v2rayA: 20170 socks5 / 20171 http / 20172 http(带分流) / 2017 web 面板; clash/mihomo: 7890 mixed / 9090 控制 API; sing-box: 视配置 (常见 2080)。
3. **客户端控制 API**: mihomo/sing-box(clash_api) `curl -s http://127.0.0.1:9090/configs`; v2rayA `curl -s http://127.0.0.1:2017/api/version` — 可确认客户端在跑、从配置读端口。
4. **询问用户**: 说明已尝试的探测, 请用户提供代理地址 (形如 `http://127.0.0.1:<端口>` 或 `socks5://127.0.0.1:<端口>`) 或确认无代理。
5. **协议判定与验证** (对每个候选端口):

   ```bash
   curl -x http://127.0.0.1:<端口> -s -m 8 -o /dev/null -w '%{http_code}\n' https://www.google.com   # 试 http
   curl -x socks5://127.0.0.1:<端口> -s -m 8 -o /dev/null -w '%{http_code}\n' https://www.google.com # 试 socks5
   ```

   输出 2xx/3xx (google 会回 302) 即该协议可用; 4xx/5xx 说明隧道已通 (目标侧拒绝), 同样视为可用; 000 或报错 → 不可用, 换候选。**不要用 `-sI | head -1` 判定**: 经 HTTP 代理的 CONNECT 失败时首行仍会打印 "200 Connection established", 造成假阳性 (已实测)。确认无任何可用代理 → 有服务器转 §3, 无服务器转 §4。

### 2.1 是否需要透明代理

- **何时需要**: 目标程序不读 `*_proxy` 变量, 且 §2.3 的用户态强制手段也无效 (静态链接且无 graftcp、setuid、非 TCP 等) → 只能靠内核层透明代理。
- **本质区别**: 普通代理需应用配合、可精确到单命令; 透明代理是内核层全局拦截 (TUN 路由 / TPROXY / REDIRECT + fake-ip DNS), 应用无感知。
- **检测本机是否已启用透明代理** (命令与判读详见 `references/transparent-proxy.md`):

  ```bash
  ip -br link | grep -Ei 'tun|utun|tap|meta|mihomo'      # TUN 接口
  ip route get 1.1.1.1                                    # 出接口是否指向 TUN
  getent ahostsv4 www.google.com                          # 是否解析出 198.18.x.x (fake-ip)
  curl -s --noproxy '*' https://api.ipify.org             # 与走代理的出口 IP 对比
  ```

- **临时局部启用不可行** (调研结论): netns/veth、按 UID 过滤等方案仍需 root 与全局路由态, 复杂易错 — **本 skill 不临时搭建透明代理**。
- **处理**:
  - 已检测到全局透明代理生效 → 目标命令直接执行即可被代理, 用原失败命令验证后使用; 任务结束提醒用户可自行关闭。
  - 未检测到 → 请用户在其客户端开启全局透明代理 (通常一键), 开启后按上面命令验证; 用户拒绝/无法开启 → §5 兜底。
- 不需要透明代理 → 继续 §2.2。

### 2.2 环境变量注入 (最轻量, 首选)

> 方法来源: 社区通用做法 (本机旧脚本 by-proxies-run 即此法的封装)。注入模型为"全量双写 + NO_PROXY 防回环"。

- **单命令前缀注入, 不跨调用 export** (每次 bash 调用是独立进程, export 不会保留; env 前缀退出即无痕):

  ```bash
  env HTTP_PROXY=<地址> HTTPS_PROXY=<地址> ALL_PROXY=<地址> \
      http_proxy=<地址> https_proxy=<地址> all_proxy=<地址> \
      NO_PROXY=localhost,127.0.0.1,::1,.local,.lan,192.168.0.0/16,10.0.0.0/8 \
      no_proxy=localhost,127.0.0.1,::1,.local,.lan,192.168.0.0/16,10.0.0.0/8 \
      <命令> [参数...]
  ```

  - `<地址>` 形如 `http://127.0.0.1:<端口>`; socks 端点用 `socks5://127.0.0.1:<端口>` (部分程序只认 http:// 形式, 失败换形式再试)。有 socks5 端点时补 `SOCKS5_PROXY`/`socks5_proxy` (及 `SOCKS_PROXY`)。各变量可指向不同端点 (HTTP_PROXY 用 http://, ALL_PROXY 可指 socks5://); 只有 socks5 端点而程序不认时按 §2.3 处理。
  - 地址含用户名密码 (`http://user:pass@host:port`) 或特殊字符时整体加引号。
  - NO_PROXY 不可省: 本机/内网流量走代理会形成路由环 (agent 与本地服务、TUI 与本地 server)。
- **应用自身代理选项优先于 env** (更可靠、可精确控制; 常用表见 `references/force-proxy.md`): `git -c http.proxy=<地址> -c https.proxy=<地址>`、`curl -x <地址>`、`pip install --proxy <地址>`、`npm --proxy=<地址> --https-proxy=<地址>` 等。
- **验证**: 用注入后的命令访问真实目标, 或 `env ... curl -s -m 8 -o /dev/null -w '%{http_code}' <目标>` 输出 2xx/3xx 即通 (000 = 不通)。
- 成功 → 用此方式完成目标任务; env 前缀无残留, 无需清理, 本 skill 结束。

### 2.3 程序不读代理变量: 用户态强制工具

按"侵入程度"从低到高选择 (对比表与最小示例见 `references/force-proxy.md`):

| 顺序 | 手段 | 适用 | 局限 |
| --- | --- | --- | --- |
| 1 | 应用自身配置 (git/curl/pip/npm/…) | 首选 | 仅覆盖该应用 |
| 2 | `proxychains4` (proxychains-ng) | 动态链接程序, 单命令 | LD_PRELOAD: 静态/Go/setuid 无效, 仅 TCP |
| 3 | `graftcp` (ptrace) | Go/静态二进制, 仅 Linux | 打包覆盖少 (nixpkgs 无), 有性能损耗 |
| 4 | 透明代理 (§2.1/§2.4) | 全量接管 | 系统级、需 root、全局 |

- proxychains 要点: 命令名随发行版而异 (`proxychains` 或 `proxychains4`, 先 `command -v` 确认); 配置文件路径同样随发行版而异, **用 `-f <临时配置>` 显式指定最稳**, 临时文件放 mktemp 目录并指向已探测端口, 用完随目录删除:

  ```bash
  TMP=$(mktemp -d); printf 'proxy_dns\n[ProxyList]\nsocks5 127.0.0.1 <端口>\n' > "$TMP/pc.conf"
  proxychains4 -f "$TMP/pc.conf" <命令> [参数...]
  rm -rf "$TMP"    # 用完删临时配置 (也可归入 §6 收尾)
  ```

- 未安装 proxychains 时: nix 环境按 nix-tool skill 临时获取 (`nix shell nixpkgs#proxychains-ng -c proxychains4 ...`), 其他环境用对应包管理器; 不值得为一次性用途装进系统。
- graftcp: 上游活跃但发行版打包少 (nixpkgs 无, 已核验); 仅当 proxychains 明确无效 (静态/Go) 且程序在 Linux 上时考虑, 获取方式见 `references/force-proxy.md` §4。
- 每级只试一次; 失败记录原因 (现象 → 判因 → 升级)。

### 2.4 仍失败 → 透明代理路径

env 与用户态强制都失败 → 需要透明代理, 按 §2.1 的检测与处理执行 (复用已有全局透明代理, 或请用户开启)。透明代理生效后, 目标命令**不再需要 env 注入** (应用无感知), 直接执行并验证。

### 2.5 兜底 (所有手段失败)

明确告知用户, 一次讲清: ①任务无法完成; ②原因归类 (程序不读变量且强制手段无效 / 代理未运行 / 端口协议不符 / 无可用代理); ③已尝试的手段列表; ④用户可做的下一步 (开启代理软件、提供服务器信息、开启透明代理)。**停止重试** — 不允许网络重试死循环。

## 3. 无本地代理但有服务器: 临时构建客户端

> 触发: §2.0 探测无果, 但用户有服务器信息 (订阅 URL 或 `vmess://`/`vless://`/`ss://`/`trojan://`/`hysteria2://` 分享链接)。目标: 拉起 127.0.0.1 的本地 HTTP/SOCKS 混合入站, 然后回到 §2 当作"已有代理"使用。

### 3.1 客户端选型

| 客户端 | 判定 |
| --- | --- |
| **sing-box** (首选) | 单二进制 + 单 JSON + `run -c` 一条命令拉起 mixed 入站; 协议覆盖最广; 无内置分享链接转换 (需手工解码, 见 clients.md) |
| **mihomo** (次选) | YAML; `proxy-providers` 原生消费分享链接/订阅 URL, 免手工解码; 注意 `-d` 指定临时工作目录 |
| xray | 无 mixed 单端口 (需 socks+http 两个 inbound); 仅用户明确指定时用 |
| v2rayA | Web UI + JWT 多步 + 持久数据库, 不适合 agent 一次性临时场景, 不推荐 |
| 专用内核 (shadowsocks-rust / hysteria) | 仅在只有单一协议链接时考虑 |

### 3.2 获取客户端 (临时)

- nix 环境: 走 nix-tool skill 的临时获取 (`nix shell nixpkgs#sing-box -c sing-box ...` / `nixpkgs#mihomo` / `nixpkgs#xray`)。
- **客户端本体通常无需代理即可获得** (避免"鸡生蛋"): nix 走 substituters 镜像、发行版走国内镜像源、或经 ghproxy 校验后下载官方二进制; 这些渠道也失败时先按 §1.2 修获取链路, 不要假设"必须先有代理"。
- 其他包管理器: `apt install` / `dnf install` / `brew install`, 或下载官方预编译二进制到临时目录。
- 不擅自持久安装; 用户要求长期使用时建议走其系统的声明式/包管理配置, 本 skill 只给建议。

### 3.3 配置与启动 (模板见 references/clients.md)

工程要点:

- 配置写入 `mktemp -d` 临时目录并 `chmod 600` (含 UUID/密码等凭证); 绝不写入 `~/.config/*` 持久目录, 不提交进任何仓库。
- 入站必须 `listen: 127.0.0.1` (防暴露内网), 端口选随机空闲 (避免与常见端口冲突)。
- 分享链接 → 配置: mihomo 直接写 `uri` 格式文件给 provider; sing-box 手工解码 (vmess base64 JSON / vless URI / ss SIP002, 规则见 clients.md §2)。
- 后台启动 + PID 记录 + 日志文件 (命令形态因客户端而异: sing-box/xray 用 `run -c <配置>`, mihomo 用 `-d <临时目录> -f <配置>`):

  ```bash
  nohup sing-box run -c "$CFG" >"$LOG" 2>&1 & echo $! > "$PID"   # mihomo: nohup mihomo -d "$TMPD" -f "$CFG" ...
  ```

- 就绪检测 (双确认): `ss -tlnp 2>/dev/null | grep <端口>` + `curl -x http://127.0.0.1:<端口> -s -m 10 -o /dev/null -w '%{http_code}' https://www.google.com` (2xx/3xx 即通)。

### 3.4 复用 §2 流程

客户端就绪后它就是"本机已有代理": 回 §2.2 用 env 注入完成目标任务 (或 §2.3 强制)。任务结束后按 §6 清理 (kill 进程 + 删临时目录)。

## 4. 无服务器: 公开代理的安全评估

> 触发: 无本地代理、用户也无服务器/订阅信息。**默认结论: 不使用公开免费代理** — 学术证据 (MADWeb 2024, 64 万代理 30 个月追踪): 约 38% 可用代理存在内容篡改, 大量代理跑在被入侵设备上; MITM 证书替换与 HTTP 降级是常态, "全程 TLS" 只在严格校验证书且代理为盲转发 (SOCKS/CONNECT) 时成立。

- **红线 (一律禁用)**: 任何携带 API 密钥 / 登录凭证 / Cookie / 私库 token / 登录态的流量。理由: 免费代理是蜜罐/肉鸡高发区, 凭据泄露风险不可接受。
- **极端兜底** (仅当以下条件**全部**满足, 且已明确告知用户风险): ①目标为公开非敏感内容; ②流量零凭证; ③只用 SOCKS5 (禁纯 HTTP 代理, 防降级嗅探); ④客户端强制证书校验 (无 `-k`/`--insecure`); ⑤无可用镜像替代; ⑥短时一次性使用, 下载后校验哈希。完整评估清单见 `references/mirrors.md` §2。
- **Tor** (本机 `tor` 包可提供 127.0.0.1:9050 SOCKS): 大陆直连被封 (需网桥), 出口被大量站点封禁, 不适合下载/API 场景 — 不推荐为常规方案。
- **兜底输出**: 明确告知用户无法安全地完成该网络任务, 给出选项: ①用户提供服务器/订阅信息 → 转 §3; ②用户开启本机代理工具 → 转 §2; ③放弃该任务。不要擅自搜罗公开代理来"碰运气"。

## 5. 失败兜底与沟通规范

- 每级手段只试一次, 失败原因归类: 程序不读 `*_proxy` 且强制手段无效 / 代理未运行 / 端口协议不符 / 无任何可用代理 / 用户拒绝开启。
- 报告格式 (一次讲清): **结论** (无法完成/已完成) + **已尝试** (列表) + **原因** + **用户下一步选项**。
- 绝不进入网络重试死循环; 同一失败原因不重复尝试。

## 6. 清理执行残留

任务完成或放弃后:

1. **后台客户端进程** (仅 §3 场景):

   ```bash
   kill "$(cat "$PID" 2>/dev/null)" 2>/dev/null; pgrep -af '<客户端>' || true   # 确认无残留
   ```

2. **临时目录** (含凭证的配置/日志, 必须删):

   ```bash
   rm -rf "$TMPDIR"
   ```

3. **env 前缀注入**: 无需清理 (命令退出即无痕, 这正是它被首选的原因)。
4. **临时获取的软件包**: nix 环境交由系统 GC (提示用户即可, 见 nix-tool skill §6); 其他包管理器若临时安装过, 询问用户是否卸载。
5. **全局透明代理**: 本 skill 不代用户开关; 若曾请用户开启, 提醒其可自行关闭。
6. **汇报** (一两句): 用了什么方式 / 是否留痕 / 复现命令。

## 7. 边界与交接

- 不修改系统路由/防火墙规则/持久代理配置; 不搭建代理服务端 (服务端搭建与节点维护不属本 skill)。
- 换镜像源的具体持久配置 (写入 .npmrc/pip.conf 等) 不属本 skill — 本 skill 只用临时参数, 并建议用户自行持久化。
- agent 自身与模型 API 的网络连接 → harness/用户配置层。
- nix 拉包层的镜像/代理 (substituters、daemon 代理) → nix-tool skill 的 §2。

## References (按需读取, 不预先加载)

- `references/clients.md` — 客户端选型盘点、sing-box/mihomo 最小配置模板、分享链接解码规则、临时拉起/停止完整命令序列。§3 需要时读取。
- `references/transparent-proxy.md` — 透明代理原理、检测命令与判读、客户端特征 (端口/接口/API)、临时局部启用为何不可行。§2.1/§2.4 需要时读取。
- `references/force-proxy.md` — 强制代理工具对比 (proxychains/graftcp/redsocks/gost/socat)、应用自身代理选项表、最小示例。§2.3 需要时读取。
- `references/mirrors.md` — 换源替代代理决策表 (pip/npm/Go/Rust/Maven/HF/Docker/GitHub) 与公开代理安全评估清单。§1.2/§4 需要时读取。
