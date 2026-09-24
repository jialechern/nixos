{ pkgs, ... }:

{
  # --- --- --- 壁纸 --- --- ---
  # awww 由 HM 模块托管 (在 graphical-session.target 之后启动, 且带头
  # ConditionEnvironment=WAYLAND_DISPLAY); 它不认 --cache-dir/--log-level 参数
  services.awww.enable = true;

  # waypaper 是壁纸前端 (niri 的启动项与快捷键调用它)
  # 壁纸目录 ~/Wallpapers 由 home.nix 的 xdg.userDirs.extraConfig.WALLPAPERS
  # 声明并自动创建, 这里不重复声明
  home.packages = [ pkgs.waypaper ];
}
