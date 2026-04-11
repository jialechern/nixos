{ config, pkgs, ... }:

{
  services.swayidle = {
    enable = true;

    # swayidle -w 参数在 Home Manager 中默认启用
    # 它会确保 swayidle 在锁屏程序退出前不会继续执行后续动作

    timeouts = [
      # 十五分钟 (900秒) 自动锁屏
      {
        timeout = 900;
        # 如果是 NixOS 则使用 nix 安装的 swaylock 反之则使用本地系统安装的 swaylock, 为防止本地用户密码无法通过验证
        command = "${config.programs.swaylock.package}/bin/swaylock";
      }

      # 半小时 (1800秒) 自动熄屏，并在恢复时点亮
      {
        timeout = 1800;
        # 熄屏动作
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        # 对应命令中的 resume 动作: 当用户活动时恢复屏幕
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];

    # 由于"永不休眠", 不需要配置 systemd 的 sleep 目标
    # 也不需要配置 events 列表中的 before-sleep
  };
}
