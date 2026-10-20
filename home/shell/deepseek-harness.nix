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
  dsh = pkgs.deepseek-harness;
in
{
  # bubblewrap: dsh 的 Linux 沙箱 runner 链是 bwrap -> Landlock
  # (packages/sandbox/sandbox-local, 用 spawnSync('bwrap') 走 PATH 探测),
  # 而 nixpkgs 的 dsh wrapper 只往 PATH 里塞了 pnpm, 不含 bwrap; 不装就会退化到
  # Landlock。两者都不可用时 dsh 是 fail closed (SANDBOX_UNAVAILABLE), 命令直接不跑。
  home.packages = [
    dsh
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
      # 目录本身由 home.nix 的 xdg.userDirs.extraConfig.DEEPSEEKHARNESS
      # 声明式创建 (随 createDirectories 建成的实体可写目录)。
      WorkingDirectory = "${config.home.homeDirectory}/DeepseekHarness";

      # --no-open: 服务没有浏览器, 不加的话每次启动都尝试打开默认浏览器并失败。
      # 端口与监听地址保持上游默认 (127.0.0.1:3080), 因此不写 --port / --host。
      ExecStart = "${lib.getExe dsh} web --no-open";

      # 每次重启 launch token 与浏览器 cookie 都重新生成 (逐进程 randomBytes),
      # 取新地址: journalctl --user -u deepseek-harness -o cat | grep 'dsh web:'
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
