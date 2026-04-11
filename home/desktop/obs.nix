{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;

    # 启用所需的插件
    plugins = with pkgs.obs-studio-plugins; [
      # 针对 wlroots 混成器 (比如 Sway/Niri) 的高效屏幕捕捉
      wlrobs

      # 现代化的 PipeWire 桌面和音频捕捉支持 (Wayland 必备)
      obs-pipewire-audio-capture

      # 针对 Vulkan/OpenGL 游戏和应用的高效捕获
      obs-vkcapture

      # 硬件加速相关的 GStreamer 支持
      obs-gstreamer

      # 一个很实用的小插件: 无需绿幕的 AI 背景去除
      obs-backgroundremoval

      # 如果偶尔需要高级的 3D 效果或者复杂的转场
      obs-3d-effect
      waveform
    ];
  };

  # 确保环境能够让 OBS 原生运行在 Wayland 上
  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    # 强制 OBS 使用 Wayland 原生运行，而不是走 Xwayland
    OBS_USE_EGL = "1";
  };
}
