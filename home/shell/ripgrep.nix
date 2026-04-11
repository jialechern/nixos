{ config, pkgs, ... }:

{
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--max-columns=150" # 限制过长行的显示
      "--max-columns-preview" # 显示长行预览
      "--smart-case" # 智能大小写搜索
      "--glob=!.git/*" # 忽略 .git 目录
      "--type-add"
      "typst:*.yp" # 添加自定义文件类型 (例如你常用的 Typst)
    ];
  };
}
