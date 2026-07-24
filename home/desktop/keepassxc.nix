{ pkgs, config, inputs, ... }:

{
  # 安装 KeePassXC 软件包
  home.packages = with pkgs; [
    keepassxc
  ];

  # --- --- --- 链接 keepassxc 配置目录 --- --- ---
  xdg.configFile."keepassxc" = {
    source = inputs.keepassxc-dotfiles;
    recursive = true;
  };
}
