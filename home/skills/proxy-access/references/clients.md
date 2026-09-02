# 代理客户端与临时拉起 (proxy-access references)

> 适用场景: SKILL.md §3 — 无本地代理但有服务器信息 (订阅 URL / 分享链接), 临时拉起本地入站。
> 客户端版本迭代快, 文中不硬编码版本号; 获取时以包管理器当前版本为准 (nixpkgs attrpath 已经本地 `nix search` 核验)。

## 1. 客户端选型盘点 (2025-2026 快照)

| 客户端 | nixpkgs | 配置 | 无头临时拉起 | 判定 |
| --- | --- | --- | --- | --- |
| sing-box | `sing-box` | JSON | ✅ 单命令 `run -c` | **首选** |
| mihomo | `mihomo` | YAML | ✅ 需 `-d` 指定临时工作目录 | 次选 (原生吃分享链接) |
| xray | `xray` | JSON | ✅ 但无 mixed 单端口入站 | 用户指定时用 |
| v2raya | `v2raya` | Web UI + 持久 DB | ⚠️ 需 JWT 多步, 不适合一次性 | 不推荐 |
| shadowsocks-rust | `shadowsocks-rust` | 仅 ss:// | ✅ `sslocal` | 仅单一 ss 链接 |
| hysteria | `hysteria` | YAML | ✅ | 仅 hysteria2:// 链接 |
| (对照) naiveproxy / trojan-go | `naiveproxy` / `trojan-go` | — | — | 低频维护 / 已归档, 勿选 |

- sing-box 协议覆盖最广 (vmess/vless/trojan/ss/hysteria2/tuic/naive/wireguard…), 无内置 UI, 最适合 agent。
- **关键事实**: sing-box 无内置"分享链接 → JSON"转换命令 (`format`/`check`/`merge` 只处理 JSON 配置); mihomo 的 `proxy-providers` 支持 `uri`/`base64` 内容格式, 可直接消费分享链接/订阅 — 这是 mihomo 的核心优势。
- 其他发行版: 官方 GitHub release 均提供预编译二进制, 可解压到临时目录使用; 部分发行版无官方包 (mihomo 等), 以 nixpkgs/官方 release 为准。

## 2. 分享链接解码规则 (sing-box 手工解码用)

| 协议 | 链接形态 | 解码 | sing-box outbound 关键字段 |
| --- | --- | --- | --- |
| vmess | `vmess://<base64>` | base64 解码得 JSON: `add/port/id/aid/net/type/host/path/tls/sni` | `type:"vmess", server(<-add), server_port(<-port), uuid(<-id), security:"auto", alter_id(<-aid, 常 0), network(<-net), tls:{enabled, server_name(<-sni)}` |
| vless | `vless://<uuid>@<host>:<port>?<query>` | URI 解析; query 含 `type=tcp\|ws\|grpc`、`security=tls\|reality`、`sni`、`fp`、`pbk`(reality 公钥)、`sid`(short_id) | `type:"vless", server, server_port, uuid, network(<-type), tls:{enabled, server_name(<-sni), reality:{enabled, public_key(<-pbk), short_id(<-sid)}}` |
| ss | `ss://<base64>` 或 SIP002 `ss://<method>:<password>@<host>:<port>` | base64 解码 `method:password@host:port` | `type:"shadowsocks", server, server_port, method, password` |
| trojan | `trojan://<password>@<host>:<port>?sni=...` | URI 解析 | `type:"trojan", server, server_port, password, tls:{enabled:true, server_name(<-sni)}` |
| hysteria2 | `hysteria2://<auth>@<host>:<port>?...` | URI 解析 | 用 `hysteria` 客户端更简; sing-box 需 hysteria2 outbound |

- 字段映射不完整时以 sing-box outbound 官方文档为准; 以链接实际参数为准做健壮解码 (vless 的 `fp`/`pbk`/`sid` 等容易漏)。

## 3. sing-box 最小配置模板

```json
{
  "log": { "level": "warn" },
  "inbounds": [
    { "type": "mixed", "tag": "in", "listen": "127.0.0.1", "listen_port": 10808 }
  ],
  "outbounds": [
    { "type": "vmess", "tag": "proxy", "server": "<服务器>", "server_port": 443,
      "uuid": "<uuid>", "security": "auto", "alter_id": 0,
      "tls": { "enabled": true, "server_name": "<sni>" } },
    { "type": "direct", "tag": "direct" }
  ],
  "route": { "final": "proxy" }
}
```

要点:

- `mixed` inbound = socks4/4a/5 + http 同端口 (按首字节区分)。`listen` 默认 `::` (全接口), **必须显式 `127.0.0.1`** 防暴露内网。
- `route.final: "proxy"` 全量走代理 (临时场景够用); 需要分流时再读官方 route 文档。
- vless/ss/trojan 只换 outbound 块 (§2 字段表)。

## 4. mihomo 最小配置模板 (原生吃分享链接)

```yaml
mixed-port: 10808
allow-lan: false
bind-address: "127.0.0.1"
mode: global
proxy-providers:
  nodes:
    type: file
    path: "<临时目录>/links.txt"     # 内容: 每行一个 vmess://vless://ss://... (uri 格式)
    health-check:
      enable: true
      url: "http://www.gstatic.com/generate_204"
      interval: 300
proxy-groups:
  - name: "PROXY"
    type: select
    use: [nodes]
rules:
  - MATCH,PROXY
```

- 订阅 URL 版: `type: http, url: "<订阅URL>", interval: 3600, path: "<临时目录>/sub.yaml"`。
- provider 内容格式 `yaml`/`uri`/`base64` 三者不能混用; `uri` = 一行一个分享链接, `base64` = 订阅内容。
- **启动必须 `-d <临时目录>`** 覆盖默认工作目录 `~/.config/mihomo` (避免写用户配置)。
- 内联节点版 (clash YAML 节点格式, 非分享链接) 见官方 `docs/config.yaml`。

## 5. xray 最小配置 (无 mixed, 双 inbound)

```json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    { "tag": "socks", "listen": "127.0.0.1", "port": 10808, "protocol": "socks", "settings": { "udp": true } },
    { "tag": "http", "listen": "127.0.0.1", "port": 10809, "protocol": "http" }
  ],
  "outbounds": [
    { "tag": "proxy", "protocol": "vmess",
      "settings": { "vnext": [ { "address": "<服务器>", "port": 443,
        "users": [ { "id": "<uuid>", "alterId": 0, "security": "auto" } ] } ] },
      "streamSettings": { "network": "tcp", "security": "tls",
        "tlsSettings": { "serverName": "<sni>" } } },
    { "tag": "direct", "protocol": "freedom" }
  ]
}
```

- 启动: `xray run -c <配置>` (新版推荐 `run` 子命令)。
- 同样无内置分享链接转换, 需手工解码或第三方工具。
- xray 26.x 起官方提示 VMess 已弃用 (无前向保密, 建议迁移 VLESS/REALITY); 本模板仅为最小示例, 有 vless 链接时优先用它。

## 6. 临时拉起与清理 (标准命令序列)

```bash
set -euo pipefail
TMPD=$(mktemp -d); chmod 700 "$TMPD"
# 随机空闲端口 (python3 可用时; 否则 shuf -i 20000-60000 -n1 后 ss -ltn 校验未占用)
PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')
# 按本文件 §3 (sing-box) / §4 (mihomo) 模板生成 "$TMPD/config.json" (heredoc 写入, 替换 <服务器>/<uuid>/$PORT)
nohup sing-box run -c "$TMPD/config.json" >"$TMPD/sing-box.log" 2>&1 & echo $! > "$TMPD/pid"
chmod 600 "$TMPD/config.json" "$TMPD/sing-box.log"     # 配置含凭证, 收紧权限
sleep 1
ss -tlnp | grep ":$PORT" || tail -n 20 "$TMPD/sing-box.log"          # 就绪检测 1: 端口监听
curl -x http://127.0.0.1:$PORT -s -m 10 -o /dev/null -w '%{http_code}\n' https://www.google.com   # 就绪检测 2: 2xx/3xx 即通, 000 失败
# --- 使用: env HTTP_PROXY=http://127.0.0.1:$PORT ... <命令> (SKILL.md §2.2) ---
kill "$(cat "$TMPD/pid")" 2>/dev/null; sleep 1
pgrep -af sing-box || true                                # 确认无残留
rm -rf "$TMPD"                                            # 凭证随目录删除
```

- 就绪检测以"端口监听 + 代理探测 2xx/3xx"双确认; 失败先看日志再重试一次, 不要盲目等待。注意别用 `-sI | head -1` 判定: CONNECT 失败时首行仍是 "200 Connection established" (假阳性)。
- 客户端退出用 `kill` (SIGTERM) 即可, 确认用 `pgrep -af`。
- mihomo 同理, 命令换成 `mihomo -d "$TMPD" -f "$TMPD/config.yaml"`; xray 换成 `xray run -c ...`。
- 长驻场景 (需客户端存活跨多次 bash 调用) 时, 上述 nohup + PID 文件已满足; 不要为此引入 tmux 等额外依赖。
