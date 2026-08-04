{ pkgs, lib, ... }:

let
  # 导入配置
  base = if builtins.pathExists ./opencode/base.nix then import ./opencode/base.nix else { };
  permission = if builtins.pathExists ./opencode/permission.nix then import ./opencode/permission.nix else { };
  provider = if builtins.pathExists ./opencode/provider.nix then import ./opencode/provider.nix else { };
  mcp = if builtins.pathExists ./opencode/mcp.nix then import ./opencode/mcp.nix else { };
  lsp = if builtins.pathExists ./opencode/lsp.nix then import ./opencode/lsp.nix else { };
  formatter = if builtins.pathExists ./opencode/formatter.nix then import ./opencode/formatter.nix else { };
  agent = if builtins.pathExists ./opencode/agent.nix then import ./opencode/agent.nix else { };
  keybinds = if builtins.pathExists ./opencode/keybind.nix then import ./opencode/keybind.nix else { };
  command = if builtins.pathExists ./opencode/command.nix then import ./opencode/command.nix else { };

  # 生成配置
  finalConfig = lib.foldl' lib.recursiveUpdate { } [
    base
    { inherit permission; }
    { inherit provider; }
    { inherit mcp; }
    { inherit lsp; }
    { inherit formatter; }
    { inherit agent; }
    { inherit keybinds; }
    { inherit command; }
  ];

  # 免费模型优先选择: 从 opencode models 输出中过滤标记为 free 的模型
  # shuf -n 1 随机选取一个; 若 shuf 不可用则回退 head -n 1 取首个
  # 无 free 模型时 grep 输出为空, MODEL 即为空, 后续回退到配置默认模型
  selectFreeModel = "MODEL=$(opencode models 2>/dev/null | grep -i free | (shuf -n 1 2>/dev/null || head -n 1));";
in
{
  programs.opencode = {
    # 必须启用 OpenCode 才会安装软件包和生成配置
    enable = true;

    # 使用包装过后的软件包
    package = pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [ pkgs.opencode ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --run '
            SECRET_FILE="$HOME/.config/opencode/secrets.env"
            if [ -f "$SECRET_FILE" ]; then
              set -a
              source "$SECRET_FILE"
              set +a
            fi
            # 启用 opencode 内置 websearch 工具 (Exa AI, 无需 API key)
            export OPENCODE_ENABLE_EXA=1
          '
      '';
    };
  };

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON finalConfig;

  # --- shell 别名 ---
  programs.bash.shellAliases = {
    code = ''${selectFreeModel} _code() { if [ -n "$MODEL" ]; then opencode --model "$MODEL" "$@"; else opencode "$@"; fi; }; _code'';
    oclean = "for s in $(opencode session list | awk 'NR > 2 {print $1}'); do opencode session delete $s; done";
  };

  # oclean 含 for 循环块, fish 的 alias 包装会与 end 冲突, 改用 function
  programs.fish.functions.oclean = ''
    for s in (opencode session list | awk 'NR > 2 {print $1}')
      opencode session delete $s
    end
  '';

  # code: 启动 opencode TUI, 免费模型优先
  programs.fish.functions.code = ''
    set -l free_models (opencode models 2>/dev/null | grep -i free)
    if test (count $free_models) -gt 0
      set -l MODEL $free_models[(random 1 (count $free_models))]
      command opencode --model $MODEL $argv
    else
      command opencode $argv
    end
  '';

  programs.zsh.shellAliases = {
    code = ''${selectFreeModel} _code() { if [ -n "$MODEL" ]; then opencode --model "$MODEL" "$@"; else opencode "$@"; fi; }; _code'';
    oclean = "for s in $(opencode session list | awk 'NR > 2 {print $1}'); do opencode session delete $s; done";
  };
}
