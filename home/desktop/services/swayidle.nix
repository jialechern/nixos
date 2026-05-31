{ config, pkgs, ... }:

{
  services.swayidle = {
    enable = true;

    # 在命令执行完毕前阻塞，确保锁屏等关键操作先完成
    extraArgs = [ "-w" ];

    # --- 空闲超时动作（不含自动锁屏） ---
    timeouts = [
      # 十分钟（600 秒）无活动后自动关闭显示器
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        # 恢复活动时点亮显示器
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];

    # --- 系统电源事件 ---
    events = {
      # 系统进入睡眠前锁定屏幕
      before-sleep = "${config.programs.swaylock.package}/bin/swaylock";

      # 系统从睡眠恢复后确保显示器点亮
      after-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
    };
  };
}
