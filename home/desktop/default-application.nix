{ config, pkgs, ... }:

{
  # --- --- --- XDG 默认应用配置 --- --- ---
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # 终端模拟器 (虽然部分应用不直接通过 MIME 调用，但配置在此可保持一致性)
      "x-scheme-handler/terminal" = [ "ghostty.desktop" ];

      # 浏览器
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];

      # 文本编辑器
      "text/plain" = [ "nvim.desktop" ];
      "text/markdown" = [ "nvim.desktop" ];
      "text/x-tex" = [ "nvim.desktop" ];
      "text/x-python" = [ "nvim.desktop" ];
      "text/x-shellscript" = [ "nvim.desktop" ];

      # 文件管理器
      "inode/directory" = [ "thunar.desktop" ];

      # 图片查看器
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      "image/png" = [ "org.gnome.Loupe.desktop" ];
      "image/gif" = [ "org.gnome.Loupe.desktop" ];
      "image/webp" = [ "org.gnome.Loupe.desktop" ];
      "image/bmp" = [ "org.gnome.Loupe.desktop" ];
      "image/tiff" = [ "org.gnome.Loupe.desktop" ];
      "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];

      # 电子书与 PDF 查看器
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
      "application/x-filler" = [ "org.pwmt.zathura.desktop" ];
      "image/vnd.djvu" = [ "org.pwmt.zathura.desktop" ];
      "application/x-cbr" = [ "org.pwmt.zathura.desktop" ];
      "application/x-cbz" = [ "org.pwmt.zathura.desktop" ];
    };
  };
}
