{ config, pkgs, ... }:

let
  # 锁屏命令 (swaylock 配置里 daemonize = true, 即锁定建立后才返回)
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
in
{
  services.swayidle = {
    enable = true;

    # (-w = 等命令执行完毕再继续, 是 HM 默认值, 不再显式声明)

    # --- 空闲超时动作 ---
    timeouts = [
      # 十分钟（600 秒）无活动后自动关闭显示器
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        # 恢复活动时点亮显示器
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
      # 十五分钟（900 秒）无活动后锁屏
      {
        timeout = 900;
        command = swaylock;
      }
    ];

    # --- 系统/会话事件 ---
    events = {
      # 系统进入睡眠前锁定屏幕
      before-sleep = swaylock;

      # 响应 loginctl lock-session 等外部锁定请求
      lock = swaylock;

      # 系统从睡眠恢复后确保显示器点亮
      after-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
    };
  };
}
