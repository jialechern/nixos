{ config, pkgs, ... }:

{
  # --- --- --- 依赖程序 --- --- ---
  home.packages = with pkgs; [
    source-han-sans # 思源黑体
    source-han-serif # 思源宋体
  ];

  # --- --- --- mpv 配置 --- --- ---
  programs.mpv = {
    enable = true;

    # --- --- --- 视频/音频/基础配置 (mpv.conf) --- --- ---
    config = {
      # --- 基础行为 ---
      save-position-on-quit = true; # 退出时保存播放位置
      load-scripts = true; # 启用脚本
      keep-open = "yes"; # 播放完毕是否自动退出
      force-window = "yes"; # 总是显示窗口

      # --- 视频输出与 Wayland 优化 ---
      vo = "gpu-next"; # 使用下一代 GPU 渲染器
      # gpu-api = "vulkan";     # (核显电脑可能会不支持) Wayland 下 Vulkan 通常性能更好且更稳定
      hwdec = "auto-safe"; # 自动硬件解码
      profile = "high-quality"; # 高质量配置文件

      # --- 增强: 抗色带/断层 (Debanding) ---
      # 非常适合动画和低码率视频，防止色彩断层
      deband = "yes";
      deband-iterations = 4; # 迭代次数
      deband-threshold = 48; # 阈值
      deband-range = 16; # 范围
      deband-grain = 48; # 动态噪声，有助于掩盖断层

      # --- 增强: 运动补偿 (Interpolation) ---
      # 让视频播放更丝滑, 匹配显示器刷新率
      video-sync = "display-resample";
      interpolation = "yes";
      tscale = "oversample";

      # --- 音频配置 ---
      ao = "pulse"; # 适配 PulseAudio/Pipewire
      audio-channels = "stereo";
      volume = 50;
      audio-pitch-correction = "yes";

      # --- 字幕与 OSD (思源黑体) ---
      sub-auto = "fuzzy";
      sub-font = "Source Han Sans";
      sub-bold = "yes";
      sub-font-size = 36;
      sub-color = "#FFFFFFFF";
      sub-border-color = "#FF000000";
      sub-border-size = 1.5;
      sub-shadow-offset = 1.5;
      sub-shadow-color = "#80000000";
      sub-back-color = "#77000000";

      osd-font = "Source Han Sans";
      osd-font-size = 24;
      osd-border-style = "outline-and-shadow";
      osd-duration = 3000;
      osd-blur = 0.7;

      # --- 窗口界面 ---
      autofit-larger = "90%x90%";
      autofit-smaller = "30%x40%";
      keepaspect = "yes";
      border = "no"; # 使用无边框
      fullscreen = true;

      # --- 性能与缓存 ---
      cache = "yes";
      cache-secs = 10;
      demuxer-max-bytes = "500MiB";
      vd-lavc-threads = 0; # 自动多线程解码

      # --- 高级缩放算法 ---
      scale = "ewa_lanczos";
      cscale = "ewa_lanczos";
      dscale = "mitchell";

      # --- 截图配置 ---
      screenshot-format = "png";
      screenshot-jpeg-quality = 95;
      screenshot-template = "mpv-shot-%F-%T";
      screenshot-directory = "~/Pictures/mpv-screenshots";
    };

    # ==================== 键位绑定 (input.conf) ====================
    bindings = {
      # 基础
      "i" = "script-binding console/enable";
      "SPACE" = "cycle pause";
      "CTRL+q" = "quit";
      "Q" = "quit";
      "x" = "quit-watch-later";
      "CTRL+c" = "quit 4";
      "CTRL+?" = "show-text \${filename}";

      # HJKL 导航 (音量与跳转)
      "h" = "seek -5";
      "l" = "seek 5";
      "j" = "add volume -2";
      "k" = "add volume 2";
      "m" = "cycle ao-mute";

      # 大范围跳转
      "H" = "seek -60";
      "L" = "seek 60";
      "p" = "seek -600";
      "n" = "seek 600";

      # 注: 在 nix 字符串中使用 \${} 来转义，防止被 nix 解析
      "<" = "frame-back-step ; show-text '当前帧: \${estimated-frame-number}'";
      ">" = "frame-step      ; show-text '当前帧: \${estimated-frame-number}'";

      # --- 按章节跳转 ---
      "," = "add chapter -1";
      "." = "add chapter 1";

      # 精确/百分比跳转
      "0" = "seek 0 absolute-percent exact";
      "g" = "seek 0 absolute-percent exact";
      "G" = "seek 90 absolute-percent exact";
      "$" = "seek 90 absolute-percent exact";
      "1" = "seek 10 absolute-percent exact";
      "2" = "seek 20 absolute-percent exact";
      "3" = "seek 30 absolute-percent exact";
      "4" = "seek 40 absolute-percent exact";
      "5" = "seek 50 absolute-percent exact";
      "6" = "seek 60 absolute-percent exact";
      "7" = "seek 70 absolute-percent exact";
      "8" = "seek 80 absolute-percent exact";
      "9" = "seek 90 absolute-percent exact";

      # 播放列表
      "CTRL+l" = "show-text \${playlist}";
      "CTRL+n" = "playlist-next";
      "CTRL+p" = "playlist-prev";
      "r" = "playlist-shuffle";
      "R" = "playlist-unshuffle";

      # 速度控制
      "[" = "add speed -0.1";
      "]" = "add speed 0.1";
      "{" = "add speed -0.5";
      "}" = "add speed 0.5";
      "|" = "set speed 1.0";

      # A-B 循环点 (Vim 标记操作)
      "CTRL+m" = "ab-loop";

      # 窗口调整
      "-" = "add window-scale -0.1";
      "+" = "add window-scale 0.1";
      "=" = "add window-scale 1.0";
      "a" = "cycle video-aspect-override";

      # 字幕与音轨
      "t" = "cycle audio";
      "s" = "cycle sub";
      "LEFT" = "add sub-delay -0.1";
      "RIGHT" = "add sub-delay +0.1";

      # 界面与信息
      "f" = "cycle fullscreen";
      "F" = "cycle ontop";
      "?" = "script-binding stats/display-stats-toggle";
      "o" = "show-progress";
      "O" = "show-progress";
      "CTRL+s" = "screenshot video";
      "CTRL+S" = "screenshot";

      # 亮度对比度
      "CTRL+k" = "add brightness 1";
      "CTRL+j" = "add brightness -1";
      "CTRL+u" = "add brightness 0.0";
      "K" = "add contrast 1";
      "J" = "add contrast -1";
    };

    # ==================== 脚本推荐 (可选添加) ====================
    scripts = with pkgs.mpvScripts; [
      mpris # 允许通过 D-Bus 控制播放(Wayland 顶栏显示进度)
      uosc # 极简主义 UI, 非常适合平铺窗口管理器用户
      thumbfast # 进度条预览缩略图
    ];
  };
}
