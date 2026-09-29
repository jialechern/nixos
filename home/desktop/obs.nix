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

  # 注: 旧配置里的 OBS_USE_EGL 在 obs-studio 32.2.2 的二进制与 nixpkgs 全树都是
  # 0 命中 (变量不存在), 属死配置, 已删除; 真要让 OBS 走 Wayland 原生, 用
  # QT_QPA_PLATFORM=wayland (OBS 本体是 Qt 程序, 平台插件由 qt.nix 侧决定)
}
