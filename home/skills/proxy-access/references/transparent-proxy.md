# 透明代理: 原理、检测与临时启用结论 (proxy-access references)

> 适用场景: SKILL.md §2.1/§2.4 — 判断是否需要透明代理、检测本机透明代理、决定是否请用户开启。
> 结论先行: **"为单个命令临时开启透明代理"在实践中复杂不可靠, 本 skill 不搭建透明代理** — 单命令场景用普通代理端口 + env 注入 (真正的"局部"); 确需透明代理时只检测复用或请用户开启全局。

## 1. 透明代理 vs 普通代理 (本质区别)

| | 普通代理 (HTTP/SOCKS 端口) | 透明代理 (TUN/TPROXY/REDIRECT) |
| --- | --- | --- |
| 层次 | 应用层, 应用显式配置 | 内核层 (路由/防火墙), 应用无感知 |
| 生效范围 | 可精确到单命令/单进程 | 全局网络栈 |
| 权限 | 无需 root | 需 root, 改系统路由/防火墙 |
| 适用 | 绝大多数场景 (**首选**) | 程序完全不支持代理配置且用户态强制无效 |

## 2. 主流实现 (一句话)

- **TUN 设备 + 路由** (tun2socks, mihomo/sing-box/clash 的 TUN 模式): 建虚拟网卡, 把默认路由 (或 `0.0.0.0/1`+`128.0.0.0/1` 两条半程路由) 指向它, 用户态程序把 IP 流封装成代理协议转发。跨平台最常用。
- **TPROXY** (mangle 表): 不改源/目的地址 (靠 SO_ORIGINAL_DST 还原), TCP+UDP 均支持, Linux 上最"正统", 网关/全局场景。
- **REDIRECT** (nat 表): 改写目的地址, 仅 TCP。旧方案, 已被 TPROXY 取代。
- **fake-ip DNS**: 客户端内置 DNS 把域名答成保留段假 IP (sing-box 默认 `198.18.0.0/15`; mihomo 常见 `198.18.0.1/16`), 记录映射后按域名分流。**识别特征: 真实域名解析出 198.18.x.x**。

## 3. 检测本机是否已启用透明代理 (按信号强度)

```bash
# ① TUN 接口
ip -br link | grep -Ei 'tun|utun|tap|meta|mihomo'; ip -br addr

# ② 路由是否指向 TUN (mihomo/sing-box 常用半程路由 + 表 2022/规则 9000)
ip route show table main | head
ip route get 1.1.1.1            # 看 dev 字段是否落到 TUN 接口
ip rule show
ip route show table 2022 2>/dev/null

# ③ 防火墙规则 (TPROXY/REDIRECT 痕迹; 无权限时跳过)
sudo -n nft list ruleset 2>/dev/null | grep -Ei 'tproxy|redirect|v2raya|sing-box|dport 53' || true
sudo -n iptables -t mangle -S 2>/dev/null | grep -Ei 'TPROXY|MARK' || true

# ④ DNS 行为 (fake-ip 特征)
getent ahostsv4 www.google.com   # 198.18.x.x → fake-ip 透明代理; 明显错误 IP (如 31.13.x.x) → DNS 污染, 属"需要代理"旁证

# ⑤ 行为学对比 (最实用): 显式走代理 vs 强制直连的出口 IP
curl -s -x http://127.0.0.1:<已知代理端口> https://api.ipify.org; echo
curl -s --noproxy '*' https://api.ipify.org; echo
# 两者出口相同 (均为代理出口) → 有透明代理拦截直连; 后者为本机真实 IP → 无透明代理
```

判读注意:

- `ip route get` 的 `dev` 字段最直接; 半程路由技巧 (0.0.0.0/1) 不会出现在默认路由里, 只 grep default 会漏检。
- `--noproxy` 只禁用 env 变量, 对透明代理无效 — 这正是用它做行为学检测的原因。

## 4. 客户端启用后的特征速查

| 客户端 | 代理端口 | 控制/管理 | TUN/TPROXY 特征 |
| --- | --- | --- | --- |
| v2rayA | 20170 socks5 / 20171 http / 20172 http(带分流) | 2017 web/API (`/api/version` 可免鉴权探测) | TPROXY: 监听 52345, nftables 表 `inet v2raya`, 链 TP_* |
| clash/mihomo | 7890 mixed / 7891 socks | 9090 (`GET /configs` 看 `mode` 与 `tun.enable`) | TUN: 接口名可配 (Linux 常见 Meta/Mihomo), 表 2022/规则 9000, dns-hijack 53 |
| sing-box | 视配置 (常见 2080) | 无独立 API, 开启 clash_api 后走 9090 | TUN: 接口默认 tun0, 地址 172.18.0.1/30, 表 2022; fakeip 198.18.0.0/15 |

- mihomo 9090 若监听, `curl -s http://127.0.0.1:9090/configs` 是信息量最高的单命令。
- v2rayA 的 2017 API 多数端点需 JWT; 透明代理开关状态用 §3 的规则检测代替即可。

## 5. 为什么不做"临时局部透明代理"

三个候选方案与结论 (调研):

- **netns + veth** (`unshare -n`/`ip netns`): 需 root + 手工路由/NAT; 让宿主透明代理"看见" ns 流量还需额外 PREROUTING 规则; 跨 netns TPROXY 是社区公认踩坑点。
- **按 UID 过滤** (mihomo `include-uid`/sing-box `include_uid`): 能力存在, 但仍要求客户端常驻 TUN 全局态 — 只是缩小作用对象, 不是"零全局影响"。
- **slirp4netns**: 用户态 NAT, 适合隔离, 不适合接透明代理。

结论: 复杂、易错、仍需全局态 → 收益不抵风险。**skill 的策略: 需要透明代理时只做两件事 — 检测是否已全局生效 (复用), 或请用户一键开启 (用户操作)**。

## 6. 使用中的注意

- 透明代理生效期间, 目标命令**无需 env 注入**; 若同时再注入普通代理端口会形成双重代理 (一般无害但多余, 且可能让 fake-ip 域名解析异常)。
- 透明代理运行时, DNS 查询常被劫持到客户端 (53 端口) — 排查"域名解析异常"时先查 §3 的 ④。
- 全局透明代理是用户开启的全局态, 本 skill 不代其关闭; 任务结束提醒用户即可。
