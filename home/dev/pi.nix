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
  # 项目级扩展 (--local): 与 ./pi/extensions.nix 末尾注释的
  # "推荐使用 pi install --local 安装" 条目保持同步。
  # 需要时在项目目录内运行 pi-ext, 以 --local 形式安装到当前项目 (.pi/settings.json)
  # ---------------------------------------------------------------------------
  localExtensions = [
    "npm:pi-lens" # 实时代码反馈 (LSP 诊断 / linter / autofix)
    "npm:pi-hermes-memory" # 持久记忆 + 会话搜索 + 密钥扫描
    "npm:@vigolium/piolium" # 仓库安全审计
  ];

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
    defaultModel = "deepseek-v4-flash"; # 默认模型
    defaultThinkingLevel = "max"; # 默认思考等级

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
  # shell 别名
  # ---------------------------------------------------------------------------
  home.shellAliases = {
    ag = "pi";

    # pi-ext: 把 extensions.nix 中注释的 "--local 按需安装" 扩展装进当前项目。
    "pi-ext" = "sh -c 'for e in ${lib.concatStringsSep " " localExtensions}; do pi install --local $e; done'";

    # pi-clean: 卸载当前项目本地安装的扩展 (读取 .pi/settings.json 的 packages 字段),
    # 并清理全局残留: 全局扩展由 Nix 声明式管理, 手动 pi install 写入的
    # ~/.pi/agent/npm/package.json 依赖在 rebuild 后不被 settings.json 识别, 属垃圾文件,
    # 此处用 npm uninstall 一并清除。
    "pi-clean" = "sh -c 'if [ -f .pi/settings.json ]; then for p in $(jq -r \".packages[]\" .pi/settings.json); do pi uninstall --local $p; done; else echo \"pi-clean: 未找到 .pi/settings.json (无本地安装的扩展)\"; fi; if [ -f \"$HOME/.pi/agent/settings.json\" ] && [ -f \"$HOME/.pi/agent/npm/package.json\" ]; then cd \"$HOME/.pi/agent/npm\" || exit 0; for pkg in $(jq -r \".dependencies | keys[]\" package.json); do if ! jq -e --arg p \"npm:$pkg\" \".packages | any(. == \\$p)\" \"$HOME/.pi/agent/settings.json\" > /dev/null 2>&1; then echo \"pi-clean: 清理全局残留 $pkg\"; npm uninstall \"$pkg\"; fi; done; fi'";
  };
}
