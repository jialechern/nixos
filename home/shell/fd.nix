{ config, pkgs, ... }:

{
  programs.fd = {
    enable = true;
    hidden = true;

    # 默认搜索隐藏文件
    ignores = [
      ".git/"
      "node_modules/"
    ];

    # # 其它参数
    # extraOptions = [];
  };
}
