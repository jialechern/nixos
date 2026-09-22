{ pkgs, ... }:

{
  # --- --- --- 壁纸 --- --- ---
  # awww 由 HM 模块托管 (在 graphical-session.target 之后启动, 且带头
  # ConditionEnvironment=WAYLAND_DISPLAY); 它不认 --cache-dir/--log-level 参数
  services.awww.enable = true;

  # waypaper 是壁纸前端 (niri 的启动项与快捷键调用它)
  home.packages = [ pkgs.waypaper ];
}
