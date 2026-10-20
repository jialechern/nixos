{
  config,
  lib,
  pkgs,
  ...
}:

# DeepSeek Harness (dsh) —— Web UI + 常驻 systemd user unit
#
# 上游状态: developer preview, 明示会有破坏性兼容变更, 且未做安全审计
# (仓库 SAFETY.md)。它跑模型生成的命令、可访问网络/文件, 因此本单元有意:
#   - 只绑回环 (dsh 默认, 且拒绝 --host 0.0.0.0), 不开防火墙端口;
#   - 不注入代理: 需要时手动加 Environment, 否则模型跑的命令也能读到代理 URL;
#   - 不启用 linger: 登录后才起, 最后一个会话结束即停。
# 远程访问请用 SSH 端口转发, 不要改防火墙。
#
# 关键路径 (都由 dsh 自己创建/写入, 不可用 home.file 管理, 否则是只读 store 软链):
#   $DSH_HOME = ~/.dsh          默认家目录
#   ~/.dsh/.credentials.yaml    API key 明文落盘 (首启在 Web UI 里填)
#   ~/.dsh/profiles/web/        web profile 的 cordis.patch.yml 与插件
#   ~/.dsh/logs/                启动失败诊断报告
let
  # --- dsh-url: 取当前这一轮可用的 Web UI 地址 ---
  # dsh web 的 launch token 与会话 cookie 的签名密钥都是逐进程 randomBytes 生成的:
  # 服务每重启 (含 systemctl --user restart) 一次, 旧 URL 和浏览器里已存的 cookie
  # 一起失效, 所以只能从 journal 里取最近一次的启动播报 (它打在 stdout, 即 user journal)。
  # 直接开 http://localhost:3080/ 提示 "authentication required", 就是因为没走过
  # token URL 这一趟; 且该 cookie 是 host-only, localhost 与 127.0.0.1 互不通用,
  # 所以认证后请认准同一个主机名。
  dshUrl = pkgs.writeShellApplication {
    name = "dsh-url";
    runtimeInputs = with pkgs; [
      coreutils # tail
      gnugrep # grep
      systemd # systemctl / journalctl
      xdg-utils # xdg-open (-o)
    ];
    text = ''
      # dsh-url: 打印 (或用 -o 打开) DeepSeek Harness Web UI 当前可用的带 token 地址

      set -euo pipefail

      UNIT=deepseek-harness.service

      usage() {
        cat <<'EOF'
      用法: dsh-url [-o|-h]
        -o, --open   直接在默认浏览器中打开取到的地址
        -h, --help   显示帮助

      说明: token 在每次启动时重新生成, 旧地址与浏览器里已存的 cookie 随之失效;
            本命令取的是最近一次启动播报的地址。认证成功后请固定用同一个主机名
            (cookie 为 host-only, localhost 与 127.0.0.1 互不通用)。
      退出码: 0=成功, 1=服务未运行或日志里没有启动播报, 2=参数错误
      EOF
      }

      open=0
      case "''${1:-}" in
        "") ;;
        -o | --open) open=1 ;;
        -h | --help)
          usage
          exit 0
          ;;
        *)
          printf 'dsh-url: 未知参数 %s\n' "$1" >&2
          usage >&2
          exit 2
          ;;
      esac

      if ! systemctl --user is-active --quiet "$UNIT"; then
        printf 'dsh-url: %s 未在运行 (先 systemctl --user start %s)\n' "$UNIT" "$UNIT" >&2
        exit 1
      fi

      url="$(journalctl --user -u "$UNIT" -o cat --no-pager 2>/dev/null |
        grep -oE 'https?://[^[:space:]]*token=[^[:space:]]*' | tail -n 1)" || url=""
      if [ -z "$url" ]; then
        printf 'dsh-url: %s 的日志里没有找到带 token 的启动播报\n' "$UNIT" >&2
        exit 1
      fi

      if [ "$open" -eq 1 ]; then
        exec xdg-open "$url"
      fi
      printf '%s\n' "$url"
    '';
  };
in
{
  # bubblewrap: dsh 的 Linux 沙箱 runner 链是 bwrap -> Landlock
  # (packages/sandbox/sandbox-local, 用 spawnSync('bwrap') 走 PATH 探测),
  # 而 nixpkgs 的 dsh wrapper 只往 PATH 里塞了 pnpm, 不含 bwrap; 不装就会退化到
  # Landlock。两者都不可用时 dsh 是 fail closed (SANDBOX_UNAVAILABLE), 命令直接不跑。
  home.packages = [
    pkgs.deepseek-harness
    dshUrl # 取当前可用的 Web UI 地址 (dsh web 的 token 每次启动都变)
    pkgs.bubblewrap
  ];

  systemd.user.services.deepseek-harness = {
    Unit = {
      Description = "DeepSeek Harness Web UI (dsh web)";
      # 只监听回环, 不依赖网络就绪, 故不写 After=network-online.target
    };

    Service = {
      # dsh web 是前台常驻进程: 启动后打印一行带 token 的 URL
      # (packages/bundle/web-app/src/index.ts), 一直服务到被终止;
      # SIGTERM 被当作普通停止请求, 退出码 0 (apps/cli/src/profile-boot.ts)。
      # 所以必须是 simple/前台 —— Type=forking 或套一层后台脚本都会让
      # systemctl stop/restart 失效 (停掉的只是包装进程)。
      Type = "simple";

      # Web UI 的默认 workspace 与沙箱策略的 workspaceRoot 都取自进程 cwd
      # (base bundle: workspaceRoot: process.cwd()), 即本行决定 agent 能写哪里。
      # 故意不设 $HOME: 那等于把整个家目录交给 workspace-write 沙箱。
      # 目录本身由 home.nix 的 xdg.userDirs 声明式创建 (createDirectories 建成的
      # 实体可写目录); 这里直接取同一个值, 避免把路径写两遍。
      WorkingDirectory = config.xdg.userDirs.extraConfig.DEEPSEEKHARNESS;

      # --no-open: 服务没有浏览器, 不加的话每次启动都尝试打开默认浏览器并失败。
      # 端口与监听地址保持上游默认 (127.0.0.1:3080), 因此不写 --port / --host。
      ExecStart = "${lib.getExe pkgs.deepseek-harness} web --no-open";

      # 每次重启 launch token 与浏览器 cookie 都重新生成 (逐进程 randomBytes),
      # 取新地址用本模块安装的 dsh-url (加 -o 可直接在浏览器里打开)。
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
