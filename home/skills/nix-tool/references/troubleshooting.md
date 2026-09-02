# 故障排查表 (nix-tool references)

> nix 命令失败时先查此表: 定位现象 → 原因 → 按处置行动。处置涉及 §2/§5/§6 时, 指 SKILL.md 对应章节。

## 错误分类表

| 现象 | 原因 | 处置 |
| --- | --- | --- |
| `error: ... not found` / `attribute ... missing` | attrpath 拼错或包名不对 (命令名≠包名) | 用 SKILL.md §3 的检索命令换词再搜 (输出剥离前缀后的 attrpath); 如 `rg`→搜 `ripgrep` |
| eval 卡住/极慢 (>几分钟) | registry 源整树首次 fetch/eval; 或引用完整 `github:` 树被墙 | 属正常首次成本, 后台等待; 大陆改用 TUNA `git+https` 前缀; 检查是否引用了与系统配置锁定不同的 nixpkgs 分支 |
| `error: cannot download ... timeout/reset/TLS` | 网络受限 (拉包层) | 走 SKILL.md §2: 验 substituters 可达性 → 临时加镜像/换 TUNA 源/走 daemon 代理; 告知用户建议持久化 |
| 下载由 daemon 执行失败, 但客户端 curl 直连正常 | daemon 代理/镜像配置问题 | NixOS 查系统 nix 配置中的 substituters 与 nix-daemon 服务注入的代理环境; 客户端 export 代理无效 (分层机制, 见 SKILL.md §2) |
| `--option extra-substituters` 看起来没生效 | 你不是 trusted user, daemon 静默忽略 | `nix config show \| grep trusted-users`; 用 sudo/root 或改走 TUNA flake 引用 |
| `nix run` 报 mainProgram 缺失/列出多候选 | 包未声明 mainProgram | 改用 `nix shell nixpkgs#<pkg> -c <pkg> [-- <args>]` |
| `error: cannot substitute ... no store path` + 开始本地编译后卡死 | 二进制缓存无此包 (新包/非主流平台) | 等本地编译 (首次可能很久); 或换相近包/版本; 真不需要就放弃并如实汇报 |
| 本地编译失败且网络报错 | 构建期拉源码失败 | daemon 代理层问题, 见 §2; 个别包需 `nixpkgs.config.allowUnfree` 之类, 提示用户需声明式修改, 不硬闯 |
| `nix shell` 进入交互模式卡住 | 忘了 `-c <cmd>` (agent 无交互能力) | 总是写 `nix shell ... -c <cmd>` 单命令形态 |
| `no such file or directory` / 缺 `/lib/...` / 段错误 (运行未打包二进制) | 需要 FHS 环境 | SKILL.md §5.1: 临时 `steam-run`/`appimage-run`; 库仍缺 → 声明式 buildFHSEnv (模板见 references/fhs-env.md) |
| 程序访问外网超时/重置 (包已正常运行) | 应用层网络受限 | SKILL.md §5.2: 单命令内联代理 env (注入模型见 references/proxy.md); 不要跨调用 export |
| `@<version>` 语法报错 | 版本不存在或格式错 | 先 `nix eval nixpkgs#<pkg>.version --raw` 查当前分支实际版本; 或去掉 @ 用默认版本 |
| `permission denied` 写 store | 非 daemon 多用户外的权限问题 | NixOS 上 sudo 后 nix 操作需 `nix` 用户组/trusted; 或让用户以 root 执行 |
| 磁盘空间不足 | store 垃圾累积 (无自动 GC 的机器) | `nix store gc --dry-run` 预览 → `nix store gc`; 建议用户开启自动 GC |
| `curl` 直连国内服务也失败 | 该服务需代理 (判断错层) | 确认目标: 中国直连可达 (DeepSeek/TUNA/rsproxy) 不需代理; 需代理的走 §5.2 |

## 通用排查顺序

1. 看完整报错尾部 (`2>&1 | tail -30`), 先归类到上表。
2. 网络类 → 先分"拉包层 (§2)"还是"应用层 (§5.2)"。
3. 重试一次前先确认不是首跑求值/下载的**正常等待** (30s~数分钟)。
4. 连续两次同一失败 → 停下, 向用户汇报现象与已试方案, 不要无限重试。
