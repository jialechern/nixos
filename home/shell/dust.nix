{ config, pkgs, ... }:

{
  home.packages = [ pkgs.dust ];

  home.shellAliases = {
    # # d: 只看当前层级, 显示 10 个最大的项目
    # d = "dust -d 1 -n 10";
    # # du: 替代原始 du, 使用更直观的条形图
    # du = "dust";
  };
}
