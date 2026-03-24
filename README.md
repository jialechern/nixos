# NixOS
## 安装
1. 初次构建系统可以使用 `nixos-install.sh` 进行安装, 其中已经包含了初次运行时的国内源设置

初次运行时可以把 `modules/desktop/applications.nix` 中的**其它软件**部分注释掉, 这些软件有些需要透明代理才能顺利下载, 等到初次构建成功后(v2rayA 服务已经成功部署后)再下载也是可以的.

2. niri、nvim、alacritty 以及 ghostty 这四个软件的配置是独立的, 构建时需要将它们的配置文件放在 `modules/` 下并使用和软件相同的名称作为配置文件夹的名称

若想去除这些配置, 只需要将 `modules/` 下的同名的 `*.nix` 文件删掉即可.
