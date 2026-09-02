# 代理注入与验证 (nix-tool references)

> 本节只处理"**已有代理可用**时的最小注入"。完整探测、判断是否需要代理、无代理时临时构建客户端等, 属网络代理类 skill 的职责。
> 适用场景: SKILL.md §5.2 — 临时环境下运行的程序 (nix shell/run 拉下来的工具) 访问外网失败。

## 1. 注入模型 (核心纪律)

程序读取的代理变量各不相同 (有的认大写, 有的认小写, 有的只认 `ALL_PROXY`), 因此注入要**全量双写**, 且必须有 NO_PROXY 防止本机/内网流量回环:

```bash
env HTTP_PROXY=<addr> HTTPS_PROXY=<addr> ALL_PROXY=<addr> \
    http_proxy=<addr> https_proxy=<addr> all_proxy=<addr> \
    NO_PROXY=localhost,127.0.0.1,::1,.local,.lan,192.168.0.0/16,10.0.0.0/8 \
    no_proxy=localhost,127.0.0.1,::1,.local,.lan,192.168.0.0/16,10.0.0.0/8 \
    <cmd> [args...]
```

- `<addr>` 形如 `http://127.0.0.1:<port>`; socks 代理形如 `socks5://127.0.0.1:<port>` (部分程序仅认 http:// 形式, 失败时换形式试)。
- **NO_PROXY 不可省**: agent 自身/本地服务 (如 TUI↔本地 server) 若走代理会形成路由环; 默认清单至少含 `localhost,127.0.0.1,::1,.local`。
- 地址含用户密码 (`http://user:pass@host:port`) 或特殊字符时整体加引号, 不要裸展开。
- **单命令作用域**: 用 `env ... <cmd>` 前缀或 `nix shell ... -c bash -c 'export ...; <cmd>'`; 不要先 export 再分步执行 (bash 调用间不保留环境)。
- 无需清理: env 前缀的命令退出后不留任何痕迹 (这正是推荐它的原因)。

## 2. 常见代理客户端默认端口表 (探测用已知信息)

若系统装有下列客户端且未改默认配置, 代理通常监听:

| 客户端 | HTTP/HTTPS 混合端口 | SOCKS5 端口 | 备注 |
| --- | --- | --- | --- |
| v2raya | `127.0.0.1:20172` (带分流) / `127.0.0.1:20171` (无分流) | `127.0.0.1:20170` | 另有 2017 web 面板/API |
| clash / mihomo | `127.0.0.1:7890` | 常与 HTTP 同端口 (混合) | 另有 9090 控制 API |
| sing-box (本地模式) | `127.0.0.1:2080` | 常与 HTTP 同端口 | 视配置 |

端口仅作候选, 必须以实际监听为准:

```bash
ss -tlnp 2>/dev/null | grep -E ':(20172|20171|20170|7890|9090|2080)\b'   # 找监听中的候选
```

## 3. 不读取代理变量的程序 (proxychains 兜底)

少数程序不认 `*_proxy` 环境变量 (静态链接或自行实现网络层)。若系统已安装 proxychains (-ng 系) 且其配置指向代理端口, 可强制代理:

```bash
proxychains4 <cmd>   # 注意: 命令名随发行版/包而异, 可能是 proxychains4 (Debian 系等) 或 proxychains
```

- **命令名检测**: `command -v proxychains4 || command -v proxychains` — 两者是同一工具 (proxychains-ng) 在不同发行版的不同命名, 不要只试其中一个就断定未安装。
- **配置文件名同样随发行版而异** (`/etc/proxychains4.conf`、`/etc/proxychains.conf` 或用户目录配置): 需确认配置中代理条目 (socks4/socks5/http) 指向当前可用的代理端口, 否则强制代理会失效。
- 局限: LD_PRELOAD 实现, 仅动态链接程序 + TCP, 静态二进制无效。
- **未安装 proxychains 时不要为兜底专门获取/配置它** — 此类程序属少数, 不值得为此增加复杂度, 直接走 §5 升级路径。

## 4. 协议判定与验证

对每个候选端口判定是 HTTP 还是 SOCKS5 代理、是否可用:

```bash
curl -x http://127.0.0.1:<port> -sI -m 8 https://www.google.com | head -1   # 试 http 协议
curl -x socks5://127.0.0.1:<port> -sI -m 8 https://www.google.com | head -1 # 试 socks5 协议
```

返回 200 (HTTP/1.1 或 HTTP/2 均可) 即该协议可用。两个都失败 → 该端口不是可用代理, 换候选或询问用户。

## 5. 失败升级与兜底 (轻量方案失败后)

env 注入不是万能的, 失败常见原因: 程序不读 `*_proxy` 环境变量、静态链接二进制 (proxychains 对静态链接也无效)、代理仅支持特定协议/需要认证、代理服务本身未运行。

升级顺序 (每级只试一次, 不重复折腾):

1. **网络代理类 skill** — 完整的代理探测/临时构建客户端/系统级处理 (若用户仓库已配置该 skill), 本文件不做系统级修改。
2. **兜底终止** — 明确告知用户「因网络受限无法完成」, 列出已尝试方案, 停止重试。

> 原则: 本 references 与 SKILL.md §5.2 只提供轻量路径; 需要深度代理治理时交给专门的网络代理类 skill, 不要在本 skill 内膨胀职责。
