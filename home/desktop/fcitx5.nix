{ config, pkgs, lib, ... }:

let
  catppuccin-rounded = pkgs.runCommand "catppuccin-fcitx5-rounded" { } ''
    mkdir -p $out
    for dir in ${pkgs.catppuccin-fcitx5}/share/fcitx5/themes/*; do
      cp -r "$dir" "$out/$(basename "$dir")"
      chmod -R u+w "$out/$(basename "$dir")"
      sed -i \
        -e 's/^# Image=panel.svg/Image=panel.svg/' \
        -e 's/^# Image=highlight.svg/Image=highlight.svg/' \
        -e 's/^Color=#313244$/Color=#313244d9/' \
        "$out/$(basename "$dir")/theme.conf"
    done
  '';
in
{
  # 强制写入 Fcitx5 的全局配置, 主题为 Catppuccin Mocha Mauve
  xdg.configFile."fcitx5/conf/classicui.conf".text = lib.mkForce ''
  		Vertical Candidate List=False
  		PerScreenDPI=True
  		Theme=catppuccin-mocha-mauve
          Font="JetBrainsMono Nerd Font Mono 12"
  		'';

  # 定义输入法顺序为: 英文 -> 拼音 -> 日文
  # 这里的格式是: 输入法名称:运行布局
  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
                  [Groups/0]
                  Name=Default
                  Default Layout=us
                  DefaultIM=keyboard-us
            
                  [Groups/0/Items/0]
                  Name=keyboard-us
                  Layout=
            
                  [Groups/0/Items/1]
                  Name=pinyin
                  Layout=
            
                  [Groups/0/Items/2]
                  Name=anthy
                  Layout=
      		'';
  };

  # 使得 fcitx5 主题插件在需要的目录下可见
  home.file.".local/share/fcitx5/themes".source = "${catppuccin-rounded}";

  # 环境变量: 确保在 Niri/Wayland 下各类应用(QT, GTK, Electron)都能正常呼出输入法
  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    # 针对某些现代 Wayland 应用, fcitx5 推荐使用文本输入协议
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus"; # 部分游戏/应用需要
  };
}
