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
#   - 不启用 linger: 随 niri 的 graphical-session.target 起停, 故纯 TTY/SSH
#     (无图形会话) 时不启动; 要支持那种用法见下方 Install 注释。
# 远程访问请用 SSH 端口转发, 不要改防火墙。
#
# 关键路径 (都由 dsh 自己创建/写入, 不可用 home.file 管理):
#   $DSH_HOME = ~/.dsh          默认家目录
#   ~/.dsh/.credentials.yaml    API key 与 cookie 签名密钥明文落盘 (key 在 Web UI 里填)
#   ~/.dsh/profiles/web/        web profile 的 cordis.patch.yml 与插件
#   ~/.dsh/logs/                启动失败诊断报告
let
  # dsh 本体: home.packages 与 systemd 单元的 ExecStart 共用这一个绑定
  dsh = pkgs.deepseek-harness;

  # --- dsh-url: 取当前这一轮可用的 Web UI 地址 ---
  # dsh web 的 launch token 逐进程 randomBytes 生成, cookie 的签名密钥则落盘
  # ($DSH_HOME/.credentials.yaml), 所以服务每重启 (含 systemctl --user restart)
  # 一次旧 URL 就失效, 已认证的浏览器 cookie 却仍然有效; token 只能从 journal 里
  # 取本次启动的播报 (它打在 stdout, 即 user journal)。
  # 没认证过的浏览器直接开 http://localhost:3080/ 会提示 "authentication required",
  # 就是没走过 token URL 这一趟 (cookie 的 host-only 细节见 usage())。
  dshUrl = pkgs.writeShellApplication {
    name = "dsh-url";
    runtimeInputs = with pkgs; [
      coreutils # cat / tail
      gnugrep # grep
      systemd # systemctl / journalctl
      xdg-utils # xdg-open (-o)
    ];
    text = ''
      # dsh-url: 打印 (或用 -o 打开) DeepSeek Harness Web UI 当前可用的带 token 地址

      UNIT=deepseek-harness.service

      usage() {
        cat <<'EOF'
      用法: dsh-url [-o|-h]
        -o, --open   直接在默认浏览器中打开取到的地址
        -h, --help   显示帮助

      说明: token 在每次启动时重新生成, 旧地址随之失效; 已认证的浏览器 cookie
            仍然有效 (签名密钥落盘, 默认 30 天), 过期、换浏览器或主机名时才需
            重新认证。
            本命令取的是本次启动播报的地址; 认证成功后请固定用同一个主机名
            (cookie 为 host-only, localhost 与 127.0.0.1 互不通用)。
      退出码: 0=成功, 1=服务未运行或日志里没有本次启动的播报, 2=参数错误
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

      # Type=simple 下, dsh 打印 URL 之前 unit 就已 active。若只取 "最近一条",
      # 重启后、新进程还没播报时会拿到上一次运行的过期 token; 按本次启动的
      # InvocationID 过滤, 没有新播报就报错 (提示稍后重试) 而不是给死链接。
      invocation="$(systemctl --user show -p InvocationID --value "$UNIT")"
      url="$(journalctl --user -u "$UNIT" \
        "_SYSTEMD_INVOCATION_ID=$invocation" -o cat --no-pager 2>/dev/null |
        grep -oE 'https?://[^[:space:]]*token=[^[:space:]]*' | tail -n 1)" || url=""
      if [ -z "$url" ]; then
        printf 'dsh-url: %s 的日志里没有找到本次启动的 token 播报 (刚重启可稍后重试)\n' "$UNIT" >&2
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
  home.packages = [
    dsh
    dshUrl

    # bubblewrap: dsh 的 Linux 沙箱 runner 链是 bwrap -> Landlock
    # (packages/sandbox/sandbox-local, 用 spawnSync('bwrap') 走 PATH 探测),
    # 而 nixpkgs 的 dsh wrapper 只往 PATH 里塞了 pnpm, 不含 bwrap; 不装就会退化到
    # Landlock。两者都不可用时 dsh 是 fail closed (SANDBOX_UNAVAILABLE), 命令直接不跑。
    pkgs.bubblewrap
  ];

  systemd.user.services.deepseek-harness = {
    Unit = {
      Description = "DeepSeek Harness Web UI (dsh web)";

      # dsh 的 open-in-app 用自身环境启动 kitty 等 GUI 程序, 因此必须等 niri 把
      # WAYLAND_DISPLAY / DISPLAY / XDG_CURRENT_DESKTOP / DBUS 地址导入 systemd
      # user manager 之后再启动 (niri 在激活 graphical-session.target 之前完成);
      # 挂 default.target 会先于 niri 启动, 点“用 kitty 打开”将立刻失败。
      # 不写 Environment=WAYLAND_DISPLAY=...: socket 名由 niri 决定, 硬编码在
      # wayland-1 被占用时会失效; 交给 graphical-session.target 继承。
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];

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
      # (base bundle: workspaceRoot: process.cwd()), 即本行决定 agent 能写哪里:
      # 整个 ~/Projects 树 (含其中已有的各项目), 而非一个专用空目录。
      # 故意不设 $HOME: 那等于把整个家目录交给 workspace-write 沙箱。
      # 路径取自 home.nix 的 xdg.userDirs.projects (默认 ~/Projects)。
      WorkingDirectory = config.xdg.userDirs.projects;

      # --no-open: 服务没有浏览器, 不加的话每次启动都尝试打开默认浏览器并失败。
      # 端口与监听地址保持上游默认 (127.0.0.1:3080), 因此不写 --port / --host。
      ExecStart = "${lib.getExe dsh} web --no-open";

      # 每次重启 launch token 都会重新生成 (逐进程 randomBytes); 取新地址用本模块
      # 安装的 dsh-url (加 -o 可直接在浏览器里打开), 已认证的浏览器 cookie 不受影响。
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      # 随 niri 图形会话起停; 纯 TTY/SSH 无图形会话时不启动。若要支持那种用法,
      # 改回 default.target 并给 Service.Environment 补上 WAYLAND_DISPLAY 等变量
      # (理由见上方 Unit 注释)。
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
