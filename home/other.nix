{ ... }:

{
  imports = [
    # FHS 兼容沙箱 (运行未打包的预编译二进制)
    ./other/fhs.nix
  ]
  ++ (builtins.filter builtins.pathExists [
    # 共享 Agent Skills (ai agent 共用, 可能需要网络代理才能拉取)
    # (pathExists 只看 git 已索引的文件: 新增后必须先 git add, 否则静默不生效)
    ./other/skills.nix
  ]);
}
