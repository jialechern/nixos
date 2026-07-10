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
          '
      '';
    };
  };

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON finalConfig;

  # --- shell 别名 ---
  programs.bash.shellAliases = {
    code = "opencode --port";
    ag = "opencode";
    oclean = "for s in $(opencode session list | awk 'NR > 2 {print $1}'); do opencode session delete $s; done";
  };

  programs.fish.shellAliases = {
    code = "opencode --port";
    ag = "opencode";
  };

  # oclean 含 for 循环块, fish 的 alias 包装会与 end 冲突, 改用 function
  programs.fish.functions.oclean = ''
    for s in (opencode session list | awk 'NR > 2 {print $1}')
      opencode session delete $s
    end
  '';

  programs.zsh.shellAliases = {
    code = "opencode --port";
    ag = "opencode";
    oclean = "for s in $(opencode session list | awk 'NR > 2 {print $1}'); do opencode session delete $s; done";
  };
}
