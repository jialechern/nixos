{ config, pkgs, lib, ... }:

let
  # ---------------------------------------------------------------------------
  # pi 配置根目录: 与上游 CLI 默认值 ~/.pi/agent 一致
  # 显式写出 (而非依赖模块默认值), 防止上游将来变更默认路径影响本配置
  # ---------------------------------------------------------------------------
  piConfigDir = "${config.home.homeDirectory}/.pi/agent";

  # 导入子模块配置 (参照 opencode.nix 的模块化模式)
  extensionsCfg =
    if builtins.pathExists ./pi/extensions.nix
    then import ./pi/extensions.nix
    else { };
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
    defaultProvider = "deepseek"; # 默认提供商: DeepSeek 官方开放平台
    defaultModel = "deepseek-v4-flash"; # 默认模型: DeepSeek V4 Flash (2026-07-31 官方正式发布)
    defaultThinkingLevel = "max"; # 默认思考等级: 最高级 (官方支持 low/high/max, max 直通)

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

    # --- Ctrl+P 循环切换的模型白名单 (模式匹配, 同 --models 格式) ---
    enabledModels = [
      "deepseek-*"
      "doubao-seed-2-0-*"
    ];

    # --- 网络代理 (可选) ---
    # 国内访问海外 API 时可取消下面注释 (本机透明代理默认 127.0.0.1:20172):
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
            export PI_OFFLINE=1
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
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
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
  # shell 别名: ag = pi (通用 agent 日常入口)
  # ---------------------------------------------------------------------------
  programs.bash.shellAliases = {
    ag = "pi";
  };

  programs.zsh.shellAliases = {
    ag = "pi";
  };

  programs.fish.shellAliases = {
    ag = "pi";
  };
}
