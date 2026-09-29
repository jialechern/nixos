{ config, pkgs, lib, username, ... }:

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

  # 内嵌 HM (submoduleSupport.enable = true) 下不需要 programs.home-manager.enable:
  # 该选项只在非内嵌时把 home-manager CLI 装进用户 profile, activation 由 NixOS 模块负责

  # --- --- --- 引入配置 --- --- ---
  imports = [

    # 基本的 Shell 配置
    ./home/shell.nix

    # 开发环境
    ./home/dev.nix

    # 其它程序配置
    ./home/other.nix

  ] ++ (builtins.filter builtins.pathExists [
    # 注意: pathExists 只看 git 已索引的文件 —— 新增这三个开关文件后必须先 git add,
    # 否则开关静默为 false (flake 源只拷贝 tracked 文件; warn-dirty 也已关掉)
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
    # 显式声明以保留旧默认 (HM 26.05 起默认改为 false), 升 stateVersion 时再决定
    setSessionVariables = true;

    # 8 个标准目录 (documents/download/pictures/videos/music/desktop/
    # publicShare/templates) 以及 projects 都等于 HM 默认值 ($HOME/同名目录),
    # 不再逐个声明; 需要改名时再显式写

    # 额外的自定义目录
    extraConfig = {
      # 壁纸目录: niri 的启动项与快捷键里写死了 $HOME/Wallpapers (见
      # home/desktop/niri/conf.d/{startup,bind}.kdl), 这里声明是为了让遵循 XDG
      # 的 GUI 程序也能找到它; 图片由用户自行放置
      WALLPAPERS = "${config.home.homeDirectory}/Wallpapers";
    };
  };

  # --- --- --- 其它细碎配置 --- --- ---
  # niri 依赖的光标配置
  home.pointerCursor = {
    enable = true;
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24;
    # 只开 GTK 侧: Wayland 会话下唯一有消费者的路径。
    # x11.enable 只做 `xsetroot -xcf` 并写 ~/.Xresources, 而 xsession.enable = false
    # 时这两样都没有读者 (属确定性失效配置), 故不开启。
    gtk.enable = true;
  };

  # --- 下载即使用的软件 ---
  # 实际包清单在各模块里; 需要临时装包时在这里加 (列表为空时不能写 `with pkgs;`)
  home.packages = [ ];

  # home.file: 声明式部署 dotfiles (各模块也有自己的 home.file / xdg.configFile)
  home.file = {
    # pi 项目级扩展集合管理脚本 (pi-init / pi-coding / pi-clean 别名调用)
    ".local/bin/pi-local-exts".source = ./home/dev/pi/pi-local-exts.sh;
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
    # EDITOR / VISUAL 由 home/shell/nvim.nix 的 programs.neovim.defaultEditor 提供

    # 默认 Shell
    SHELL = "${pkgs.fish}/bin/fish";

    # 禁止 fzf 在 tmux 中新建 pane, 改为内联显示(覆盖 fzf 模块默认的 "1")
    FZF_TMUX = lib.mkForce "0";

    # Qt 相关变量见 home/desktop/qt.nix

    # --- Rust 代理设置 ---
    # Rust 详细回溯
    RUST_BACKTRACE = "1";
    # Rust 安装源 (rsproxy 镜像)
    RUSTUP_DIST_SERVER = "https://rsproxy.cn";
    RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
  };

  # 为非 NixOS 系统导出必要的 Linux 环境变量
  # targets.genericLinux.enable = true;
}
