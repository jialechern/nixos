{ config, pkgs, lib, ... }:

let
  # ---------------------------------------------------------------------------
  # pi 配置根目录: 与上游 CLI 默认值 ~/.pi/agent 一致
  # 显式写出 (而非依赖模块默认值), 防止上游将来变更默认路径影响本配置
  # ---------------------------------------------------------------------------
  piConfigDir = "${config.home.homeDirectory}/.pi/agent";

  # 导入子模块配置
  extensionsCfg =
    if builtins.pathExists ./pi/extensions.nix
    then import ./pi/extensions.nix
    else { };

  # ---------------------------------------------------------------------------
  # 项目级扩展集合 (--local): 这些包不进全局 settings (见 ./pi/extensions.nix
  # 的 packages), 因此未装配它们的项目是零启动成本; 在项目目录内运行
  # pi-init / pi-coding 即可装配到该项目的 .pi/settings.json。
  # ---------------------------------------------------------------------------

  # 基础集合 (pi-init): 通用能力, 任何项目都可能想要
  localBaseExtensions = [
    # Codex 风格只读规划模式 (MIT, narumitw): pi 核心未内置 plan mode, 此扩展补上
    "npm:@narumitw/pi-plan-mode"
    # 自主目标模式 (MIT, narumitw): 给 pi 一个会话级目标, 让它持续工作直到完成/暂停/等待/触达安全上限
    "npm:@narumitw/pi-goal"
    # 侧线提问 (MIT, narumitw): /btw 开临时侧线程问问题, 不污染主对话, 主 agent 可继续运行
    "npm:@narumitw/pi-btw"
    # 子代理: 把任务委托给专注的子会话
    "npm:pi-subagents"
  ];

  # 编码集合 (pi-coding): 与基础集合正交, 只含编码相关
  # 装配是幂等追加, 两组叠加即得并集: 日常项目跑 pi-init 即可,
  # 编码项目再叠加 pi-coding, 主动用启动耗时换功能。
  # 需要继续细化时可再加一组 (如 localAuditExtensions → pi-audit)。
  localCodingExtensions = [
    # 持久记忆 + 会话搜索 + 密钥扫描
    "npm:pi-hermes-memory"
    # 实时代码反馈 (LSP 诊断 / linter / autofix)
    "npm:pi-lens"
    # 官方 Context7 扩展 (MIT, Upstash): 给 agent 注入最新的库文档 (不依赖训练数据)
    "npm:@upstash/context7-pi"
  ];

  # ---------------------------------------------------------------------------
  # 项目级扩展集合的装配与清理逻辑见 ./pi/pi-local-exts.sh
  # (由 home.nix 部署到 ~/.local/bin), 包列表由下面的别名传入。
  #
  # 语义是"幂等追加": 各别名只往当前项目追加自己那组包, 不卸载任何东西。
  # 所以依次运行多个别名得到的是它们的并集 —— 日常项目只跑 pi-init 保持轻量,
  # 复杂项目再叠加 pi-coding, 主动用启动耗时换功能。要回退用 pi-clean。
  # 注: --local 装配要求项目已被信任 (pi 的 trust 机制), 否则 pi install 会拒绝。
  #
  # 用 `sh <固定路径>` 调用, 既不依赖执行位, 也不会把会随内容变化的 store 路径写进别名。
  # ---------------------------------------------------------------------------
  piLocalExts = "sh ${config.home.homeDirectory}/.local/bin/pi-local-exts";

  keybindings =
    if builtins.pathExists ./pi/keybindings.nix
    then import ./pi/keybindings.nix
    else { };
  models =
    if builtins.pathExists ./pi/models.nix
    then import ./pi/models.nix
    else { };
  promptHomeFiles =
    if builtins.pathExists ./pi/prompt-templates.nix
    then (import ./pi/prompt-templates.nix) piConfigDir
    else { };
  extensionHomeFiles =
    if builtins.pathExists ./pi/extension-configs.nix
    then import ./pi/extension-configs.nix
    else { };

  baseSettings = {
    # --- 模型与思考 ---
    defaultProvider = "deepseek"; # 默认提供商
    defaultModel = "deepseek-flash"; # 默认模型
    defaultThinkingLevel = "high"; # 默认思考等级

    # --- UI 与显示 ---
    theme = "catppuccin-mocha-mauve"; # 自定义 Catppuccin Mocha (mauve 强调色) 主题

    # --- 自动压缩 (官方文档示例推荐值) ---
    compaction = {
      enabled = true;
      reserveTokens = 16384; # 为 LLM 回复预留的 token
      keepRecentTokens = 20000; # 保留不摘要的最近 token
    };

    # --- 重试 (官方文档示例推荐值) ---
    retry = {
      enabled = true;
      maxRetries = 3;
    };

    # --- 模型范围 ---
    # 注意: enabledModels 若匹配到任何模型, pi 的 /model 选择器会默认进入 scoped
    # 视图 (仅显示白名单内模型), Ctrl+P/Ctrl+\ 轮换也只在白名单内循环。
    # 这里不再设置, 保持 "all" 范围: /model 显示所有已配置 provider 的完整模型列表。
    # 如需限制轮换范围, 可在 pi 内用 /scoped-models 按会话调整。

    # --- 网络代理 (可选) ---
    # 国内访问海外 API (如 OpenCode Zen/Go ...) 时启用, 走本机代理 127.0.0.1:20172
    # pi 会将其应用为 HTTP_PROXY / HTTPS_PROXY (仅全局设置, 项目设置可覆盖)
    # httpProxy = "http://127.0.0.1:20172";
  };

  settings = lib.recursiveUpdate baseSettings extensionsCfg;
in
{
  programs.pi-coding-agent = {
    # 必须启用才会安装软件包并生成配置
    enable = true;

    # 使用包装过后的软件包: 启动时加载 sops 生成的密钥文件 (参照 opencode.nix 的做法)
    # 密钥由 sops.nix 的 "pi-secrets.env" 模板生成, 文件不存在时静默跳过
    package = pkgs.symlinkJoin {
      name = "pi-coding-agent-wrapped";
      paths = [ pkgs.pi-coding-agent ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pi \
          --run '
            SECRET_FILE="$HOME/.config/pi/secrets.env"
            if [ -f "$SECRET_FILE" ]; then
              set -a
              source "$SECRET_FILE"
              set +a
            fi
          '
      '';
    };

    # 扩展包运行时依赖: pi install npm:... 安装扩展 (如 @termdraw/pi) 需要 npm 与 bun
    # gh: pi-web-access 的 GitHub 能力 (PR/Issue 富字段视图、私有库、超大仓库 API 路径)
    #     注: gh 不读 .netrc, 认证靠 sops.nix 注入 pi 进程的 GH_TOKEN
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
      pkgs.gh
    ];

    # 配置目录 (见文件头注释)
    configDir = piConfigDir;

    inherit settings keybindings models;

    # -------------------------------------------------------------------------
    # AGENTS.md: 全局上下文 (作用于所有项目)
    # 文档: https://pi.dev/docs/latest/quickstart (Give pi project instructions)
    # 修改后需 /reload 或重启生效
    # -------------------------------------------------------------------------
    context = ./pi/AGENTS.md;
  };

  # ---------------------------------------------------------------------------
  # home.file 汇总:
  #   - 自定义主题 (Catppuccin Mocha mauve)
  #   - 扩展配置 (web-search / rpiv-todo → pi/extension-configs.nix)
  #   - 提示词模板 (/trans /impl → pi/prompt-templates.nix)
  # ---------------------------------------------------------------------------
  home.file = lib.mkMerge [
    promptHomeFiles
    extensionHomeFiles
    {
      "${piConfigDir}/themes/catppuccin-mocha-mauve.json".source =
        ./pi/catppuccin-mocha-mauve.json;
    }
  ];

  # ---------------------------------------------------------------------------
  # shell 别名
  # ---------------------------------------------------------------------------
  home.shellAliases = {
    ag = "pi";

    # pi-init: 把"基础扩展集合"追加到当前项目 (.pi/settings.json)
    "pi-init" = "${piLocalExts} install ${lib.concatStringsSep " " localBaseExtensions}";

    # pi-coding: 把"基础 + 编码扩展集合"追加到当前项目 (与 pi-init 叠加, 幂等)
    "pi-coding" = "${piLocalExts} install ${lib.concatStringsSep " " localCodingExtensions}";

    # pi-clean: 卸载当前项目全部 --local 扩展, 并清理 ~/.pi/agent/npm 的全局残留
    "pi-clean" = "${piLocalExts} clean";
  };
}
