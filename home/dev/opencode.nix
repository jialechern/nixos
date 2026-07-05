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
  };

  programs.fish.shellAliases = {
    code = "opencode --port";
    ag = "opencode";
  };

  programs.zsh.shellAliases = {
    code = "opencode --port";
    ag = "opencode";
  };
}
