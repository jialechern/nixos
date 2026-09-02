# 换源替代与公开代理安全评估 (proxy-access references)

> 适用场景: SKILL.md §1.2 (替代方案检查) 与 §4 (无服务器时的安全评估)。
> 总规则: **公开 + 版本化 + 可缓存 + 只读 → 换镜像; API / 认证 / 私有 / 推送 / 登录 / 订阅 → 受信代理或直连; 带 token 的任何请求 → 绝不走第三方镜像或公开免费代理**。

## 1. 换源替代代理: 场景表 (2025-2026 现状)

| 失败场景 | 临时换源 (不改持久配置) | 现状 | 仍需代理? |
| --- | --- | --- | --- |
| pip install 慢/超时 | `pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <pkg>` (或 aliyun) | ✅ 可靠 | 否 |
| npm install 慢/超时 | `npm install --registry=https://registry.npmmirror.com` | ✅ 可靠 | 否 |
| go install 慢/超时 | `GOPROXY=https://goproxy.cn,direct go install ...` | ✅ 可靠 | 否 |
| rustup 分发慢 | `RUSTUP_DIST_SERVER=https://rsproxy.cn RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup rustup update` | ✅ 可靠 | 否 |
| cargo 依赖慢 | 写 `~/.cargo/config.toml` 的 sparse 镜像 (`sparse+https://rsproxy.cn/index/`) — 无干净单环境变量, 改后需还原 | ✅ 可靠 | 否 |
| Maven 依赖慢 | `mvn -s /tmp/aliyun-settings.xml ...` (settings 内写阿里云 `<mirror>`) | ✅ 可靠 | 否 |
| Hugging Face 下载慢 | `HF_ENDPOINT=https://hf-mirror.com huggingface-cli download ...` | ✅ 可靠 | 否 |
| apt/dnf 慢 | TUNA/USTC/阿里云发行版镜像 (apt 可用 `-o Dir::Etc::sourcelist=` 指向临时 list) | ✅ 可靠 | 否 |
| docker pull 慢 | 前缀 `docker.m.daocloud.io/...` (或 registry-mirrors) — **先 `curl -I` 探测, 失败即回退代理**; 公共镜像 2024 起大面积失效 (USTC/SJTU 已关), 不稳定 | ⚠️ 不稳 | 部分 |
| GitHub Release/raw 下载慢 | `curl -L https://ghproxy.net/https://github.com/...` — 社区自建, 随时换域名; **下载后必须校验哈希, 禁带 token** | ⚠️ 不稳 | 部分 |
| git clone 公开库慢 | `git clone https://ghproxy.net/https://github.com/<o>/<r>.git` — 不稳定; 大库/私库走代理 | ⚠️ 不稳 | 部分 |

**镜像覆盖不了的场景 (直接判定需要代理)**: API 端点 (api.github.com、OpenAI/Anthropic 等); raw.githubusercontent.com 的可信获取; git push / 私有仓库 / LFS / SSH; npm publish / pip upload / docker push (镜像只读); Google 服务 (gcr.io 镜像已关); 订阅/节点列表更新; 任何带凭证的请求。

## 2. 公开免费代理安全评估 (SKILL.md §4 依据)

**证据 (MADWeb 2024, 64 万代理 30 个月追踪, arXiv:2403.02445)**: 约 38% 可用代理存在内容篡改; 1.7 万个代理被确认恶意篡改; 大量代理运行在被入侵设备 (MikroTik 路由器/摄像头) 上; 仅约 2.5% 能响应 HTTPS 端点 (多数逼迫客户端降级明文 HTTP)。GitHub 免费节点列表运营方自己也标注"不保证安全、勿用于登录"。

**红线 (一律禁用公开免费代理)**: 携带 API 密钥 / 登录凭证 / Cookie / 私库 token / 登录态的流量; 纯 HTTP 代理 (诱导明文降级); 客户端无法强制证书校验 (含 `-k`/`--insecure`/`sslVerify=false` 配置) 的流量。

**极端兜底的评估清单 (全部满足才可考虑, 且先告知用户风险)**:

1. 目标是公开、非敏感、版本化工件;
2. 流量零凭证 (无 key/token/密码/Cookie);
3. 只用 SOCKS5 (或支持 CONNECT 的代理), 保 TLS 端到端盲转发;
4. 客户端强制校验证书, 无任何 insecure 选项;
5. 无可用镜像替代;
6. 接受节点随时失效与内容被篡改的残留风险; 短时一次性, 下载后校验哈希。

**Tor**: 本机 `tor` 包可提供 127.0.0.1:9050 SOCKS; 但大陆直连被封 (需网桥, 不稳定), 出口被大量站点封禁 (验证码/403), 不适合下载/API。不推荐为常规方案。

## 3. 结论速记 (SKILL.md §1.2/§4 的浓缩)

- 下载类失败 → 先查本文件第 1 节换源, 解决即退出 (无代理需求)。
- 换源解决不了 → 受信代理 (用户自建/付费/本机已有客户端)。
- 没有受信代理也没有服务器 → 报告"无法安全完成", 给用户选项, 不擅自使用公开代理。
