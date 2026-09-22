{ pkgs, ... }:

{
  # --- --- --- 壁纸 --- --- ---
  # awww (后端渲染) 交给 HM 模块托管: 它在 graphical-session.target 之后启动,
  # 并带有 ConditionEnvironment=WAYLAND_DISPLAY。
  #
  # 修复: 原先手写的服务传了 awww-daemon 0.12.1 并不接受的参数
  # (--cache-dir / --log-level), 每次启动都会以
  # "Unrecognized command line argument: --cache-dir" 失败并触发重启;
  # 缓存目录本就是 ~/.cache/awww, 无需显式指定。
  services.awww.enable = true;

  # waypaper 是壁纸前端, niri 的启动项与快捷键会调用它
  home.packages = [ pkgs.waypaper ];
}
