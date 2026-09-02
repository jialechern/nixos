# shell 的共享配置:
# 通用别名与 PATH 只在此定义一次, 避免在每个 shell 文件里重复
{ config, ... }:

{
  # --- 通用别名: home.shellAliases 自动注入所有已启用的 shell ---
  home.shellAliases = {
    ff = "fastfetch";
    rsync = "rsync -arvP";
    px = "proxychains4 -q";
    ngens = "nix profile history --profile /nix/var/nix/profiles/system";
    cliph = "cliphist list | fzf | cliphist decode | wl-copy";
    tm = "tmux new-session -A -s main";
    # 一键清理 NixOS 旧世代 & 垃圾回收 Nix Store
    nclean = "sudo nix-collect-garbage -d";
  };

  # --- PATH: 全局只定义一次, 所有 shell 生效 ---
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
}
