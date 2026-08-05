{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs # 包含 node 和 npm
  ];

  # 生成 .npmrc 文件
  home.file.".npmrc".text = ''
    # --- 路径配置 ---
    # 将全局安装路径设在家目录下，避免 NixOS 只读系统的权限错误
    prefix=${config.home.homeDirectory}/.npm-global
    
    # 缓存路径也建议统一管理
    cache=${config.home.homeDirectory}/.cache/npm
    
    # --- 镜像源配置 ---
    # 阿里云 npmmirror (原淘宝 npm, 官方维护, ~10 分钟同步官方源, 国内事实标准)
    # 需要回官方源时: npm install --registry=https://registry.npmjs.org <pkg>
    registry=https://registry.npmmirror.com
    
    # --- 安装与执行配置 ---
    # 隐藏赞助信息
    fund=false
    
    # 默认初始化信息
    init-author-name=YourName
    init-author-email=your-email@example.com
    init-license=MIT
    
    # --- 性能与日志 ---
    # 减少不必要的日志输出
    loglevel=warn
    
    # 不启用全局审计
    audit=false
    
    # 在不稳定的网络下, 可以增加重试次数
    fetch-retries=5
  '';

  # 配套配置环境变量
  home.sessionVariables = {
    NODE_PATH = "${config.home.homeDirectory}/.npm-global/lib/node_modules";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
  ];
}
