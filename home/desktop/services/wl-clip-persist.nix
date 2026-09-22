{ pkgs, ... }:

{
  # --- --- --- 剪贴板历史与持久化 --- --- ---
  # 由 HM 模块托管 (服务挂在 graphical-session.target 上)
  services.wl-clip-persist = {
    enable = true;
    # 与 niri 的 clipboard { disable-primary } 冲突; 不需要主选区时可改为 "regular"
    clipboardType = "both";
  };

  services.cliphist = {
    enable = true;
    # 空 = 用 cliphist 自带默认 (模块默认是 -max-items 500 / -max-dedupe-search 10)
    extraOptions = [ ];
  };

  # niri 的剪贴板历史绑定直接用 wl-copy, 故需显式安装
  home.packages = [ pkgs.wl-clipboard ];
}
