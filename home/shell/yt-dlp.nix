{ config, pkgs, ... }:

let
  # 下载主目录
  downloadDir = "${config.home.homeDirectory}/Downloads/yt-dlp";

  # 临时目录
  tempDir = "${config.home.homeDirectory}/.cache/yt-dlp";

  # 归档文件: 避免重复下载
  archiveFile = "${config.home.homeDirectory}/.config/yt-dlp/download-archive.txt";
in
{
  programs.yt-dlp = {
    enable = true; # 启用 yt-dlp
    package = pkgs.yt-dlp; # 使用 Nixpkgs 里的 yt-dlp

    settings = {
      # 输出模板为唯一命名, 减少 Bilibili 分 P / 播放列表撞名
      output = "%(extractor_key)s/%(uploader|Unknown)s/%(id)s_%(title).200B_[%(id)s].%(ext)s";

      # 保留主目录和临时目录分离
      paths = [
        "home:${downloadDir}"
        "temp:${tempDir}"
      ];

      # 最高质量优先下载
      format = "bv*+ba/b";

      # 合并容器使用 mkv, 兼容性较好
      merge-output-format = "mkv";

      # 保存简介
      write-description = true;

      # 保存元数据 JSON
      write-info-json = true;

      # 保存播放列表附带元数据
      write-playlist-metafiles = true;

      # 下载字幕
      write-subs = true;

      # 下载自动字幕
      write-auto-subs = true;

      # 保留所有可用字幕语言
      sub-langs = "all";

      # 优先保存为 srt
      sub-format = "srt";

      # 不强制内嵌字幕, 避免某些站点的特殊字幕格式触发 ffmpeg 报错
      embed-subs = false;

      # 保存封面图
      write-thumbnail = true;

      # 封面嵌入到媒体文件
      embed-thumbnail = true;

      # 封面统一转成 jpg
      convert-thumbnails = "jpg";

      # 嵌入媒体元数据
      embed-metadata = true;

      # 嵌入章节信息
      embed-chapters = true;

      # 把 info.json 也嵌入到 mkv/mka
      embed-info-json = true;

      # 下载归档, 避免重复下载
      download-archive = archiveFile;

      # 尽量保留原始时间戳
      mtime = true;

      # 无限重试
      retries = "infinite";

      # 分片无限重试
      fragment-retries = "infinite";

      # 文件访问失败重试
      file-access-retries = 5;

      # 提取器错误重试
      extractor-retries = 5;
    };

    extraConfig = "";
  };
}
