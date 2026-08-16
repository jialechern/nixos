{ pkgs, ... }:

{
  # FHS 兼容沙箱: 运行未打包的预编译二进制 (AppImage / 第三方安装器)
  # 用法: 终端输入 `fhs` 进入环境, 与宿主共享 /nix/store 与家目录
  # 依赖缺失时: 在 targetPkgs 加命令、multiPkgs 加库即可, 无需改其它文件
  home.packages = [
    (pkgs.buildFHSEnv {
      # pname+version 新风格: 生成的 wrapper 可执行名取 pname (即 `fhs`),
      # 环境名称为 "fhs-0.1" (旧风格 name = "fhs" 仍可用, 但新写法更规范)
      pname = "fhs";
      version = "0.1";
      runScript = "bash";
      # 进入环境时 source 的片段, 供脚本判断当前是否在 FHS 环境内
      profile = "export FHS=1";
      # 顺带链接各包的 dev output (头文件等), 供环境内编译使用
      extraOutputsToInstall = [ "dev" ];

      # 环境内可执行程序 (会放进 /usr/bin 等 FHS 路径)
      targetPkgs = pkgs: with pkgs; [
        pkg-config
        ncurses
      ];

      # 环境内可见的共享库 (multiPkgs 只装库不装命令)
      # 完整清单拷贝自 nixpkgs 的 pkgs/build-support/appimage/default.nix
      # 中的 defaultFhsEnvArgs.multiPkgs (AppImage 官方 excludelist),
      # 覆盖绝大多数 AppImage 程序的运行库需求; 若上游清单更新可对照同步
      multiPkgs = pkgs: with pkgs; [
        desktop-file-utils
        libxcomposite
        libxtst
        libxrandr
        libxext
        libx11
        libxfixes
        libGL
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-plugins-base
        libdrm
        xkeyboard-config
        libpciaccess
        glib
        bzip2
        zlib
        gdk-pixbuf
        libxinerama
        libxdamage
        libxcursor
        libxrender
        libxscrnsaver
        libxxf86vm
        libxi
        libsm
        libice
        freetype
        curlWithGnuTls
        nspr
        nss
        fontconfig
        cairo
        pango
        expat
        dbus
        cups
        libcap
        SDL2
        libusb1
        udev
        dbus-glib
        atk
        at-spi2-atk
        libudev0-shim
        libxt
        libxmu
        libxcb
        libxcb-util
        libxcb-wm
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
        libGLU
        libuuid
        libogg
        libvorbis
        SDL2_image
        glew_1_10
        openssl
        libidn
        onetbb
        wayland
        libgbm
        libxkbcommon
        vulkan-loader
        flac
        libglut
        libjpeg
        libpng12
        libpulseaudio
        libsamplerate
        libmikmod
        libthai
        libtheora
        libtiff
        pixman
        speex
        SDL2_ttf
        SDL2_mixer
        libcaca
        libcanberra
        libgcrypt
        libvpx
        librsvg
        libxft
        libvdpau
        alsa-lib
        harfbuzz
        e2fsprogs
        libgpg-error
        keyutils.lib
        libjack2
        fribidi
        p11-kit
        gmp
        libtool.lib
        at-spi2-core
        pciutils
        pipewire
        libmpg123
        brotli
      ];
    })
  ];
}
