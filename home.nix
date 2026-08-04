{ config, pkgs, lib, inputs, username, ... }:

{
  # Home Manager 需要一些关于它应该管理的路径的信息
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";

  # 此值决定了您的配置与哪个 Home Manager 版本兼容
  # 这有助于避免当新的 Home Manager 版本引入向后不兼容的更改时出现破坏
  #
  # 即使您更新了 Home Manager，也不应更改此值。如果您确实
  # 想要更新此值, 请务必先查看 Home Manager 的发布说明
  home.stateVersion = "25.11"; # 请在更改前阅读注释

  # 已经通过 follows 确保了 home-manager 和 nixpkgs 的兼容性
  # 为防止出现版本检查导致的警告, 禁用版本检查
  home.enableNixpkgsReleaseCheck = false;

  # 让 Home Manager 安装和管理自身
  programs.home-manager.enable = true;

  # --- --- --- 引入配置 --- --- ---
  imports = [

    # 基本的 Shell 配置
    ./home/shell.nix

    # 开发环境
    ./home/dev.nix

    # 其它程序配置
    ./home/other.nix

  ] ++ (builtins.filter builtins.pathExists [
    # 桌面环境配置(部分需要网络代理, 非必要时可删除, 或是删除其中部分模块)
    ./home/desktop.nix

    # sops-nix 配置(需要网络代理, 非必要时可删除)
    ./sops.nix

    # 共享 Agent Skills (ai agent 共用, 可能需要网络代理)
    ./home/skills.nix
  ]);

  # --- --- --- 生成标准家目录 --- --- ---
  # 开启 XDG 用户目录管理
  xdg.userDirs = {
    enable = true;
    # 核心选项: 构建时如果不存在则自动创建
    createDirectories = true;
    setSessionVariables = true;

    # 定义具体的文件夹路径
    # 使用 "${config.home.homeDirectory}" 确保路径指向家目录
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
    music = "${config.home.homeDirectory}/Music";
    desktop = "${config.home.homeDirectory}/Desktop";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";

    # 定义额外的自定义目录
    extraConfig = {
      # # Wallpapers 文件夹已由 flake 依赖接管
      # WALLPAPERS = "${config.home.homeDirectory}/Wallpapers";
      PROJECTS = "${config.home.homeDirectory}/Projects";
      TEST = "${config.home.homeDirectory}/Test";
      STU = "${config.home.homeDirectory}/Stu";
    };
  };

  # --- --- --- 其它细碎配置 --- --- ---
  # niri 依赖的光标配置
  home.pointerCursor = {
    enable = true;
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24;
    # 同时开启 GTK 和 X11 光标支持
    gtk.enable = true;
    x11.enable = true;
  };

  # --- 下载即使用的软件 ---
  # home.packages 选项允许您将 Nix 软件包安装到您的环境中
  home.packages = with pkgs; [
    # # 将 'hello' 命令添加到环境中. 运行时它会打印友好的 "Hello, world!"
    #
    # pkgs.hello
    #
    # # 有时微调包很有用, 例如通过应用覆盖
    # # 可以直接在这里进行, 只是别忘了括号. 也可以安装 Nerd Fonts
    #
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    #
    # # 也可以直接在配置中创建简单的 shell 脚本
    # # 例如, 这将向环境添加一个 'my-hello' 命令:
    #
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager 非常擅长管理 dot 文件 (dotfiles). 管理纯文本文件的
  # 主要方式是通过 'home.file'
  home.file = {
    "Pictures/Wallpapers".source = inputs.desktop-wallpapers;

    # 个人脚本: 从 flake inputs.scripts 仓库符号链接
    ".local/bin/by-proxies-run".source = "${inputs.scripts}/by-proxies-run";
    ".local/bin/play-musics".source = "${inputs.scripts}/play-musics";

    # # 使用示例:
    # # 构建此配置将在 Nix 存储中创建 'dotfiles/screenrc' 的副本
    # # 激活配置后, '${config.home.homeDirectory}/.screenrc' 将成为指向 Nix 存储副本的符号链接
    # ".screenrc".source = dotfiles/screenrc;

    # # 您也可以直接设置文件内容
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager 也可以通过 'home.sessionVariables' 管理环境变量
  # 当使用 Home Manager 提供的 shell 时, 这些变量将被显式地加载
  # 如果不想通过 Home Manager 管理 shell, 那么需要手动加载
  # 位于以下位置之一的 'hm-session-vars.sh'：
  #
  #	${config.home.homeDirectory}/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # 或
  #
  #	${config.home.homeDirectory}/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # 或
  #
  #	/etc/profiles/per-user/${username}/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # 默认编辑器
    EDITOR = "nvim";

    # 默认 Shell
    SHELL = "${pkgs.fish}/bin/fish";

    # 禁止 fzf 在 tmux 中新建 pane, 改为内联显示(覆盖 fzf 模块默认的 "1")
    FZF_TMUX = lib.mkForce "0";

    # 强制 KeePassXC 使用 Wayland 模式, 避免缩放模糊
    QT_QPA_PLATFORM = "wayland";
    # 如果使用自动输入 (Auto-type), Wayland 下可能需要特定的支持
    QT_XCB_GL_INTEGRATION = "none";

    # --- Rust 代理设置 ---
    # Rust 详细回溯
    RUST_BACKTRACE = "1";
    # Rust 安装源 (rsproxy 镜像)
    RUSTUP_DIST_SERVER = "https://rsproxy.cn";
    RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
  };

  # 启用 home-manager 中安装的字体
  fonts.fontconfig.enable = true;
  # 为非 NixOS 系统导出必要的 Linux 环境变量
  # targets.genericLinux.enable = true;
}
