{ pkgs, ... }:

{
  # --- --- --- 剪贴板历史与持久化 --- --- ---
  # 使用 Home Manager 模块, 不再手写 systemd 服务:
  # 模块会把服务挂到 wayland.systemd.target (即 graphical-session.target) 上。
  services.wl-clip-persist = {
    enable = true;
    # 保持改动前的参数 (--clipboard both)。
    # 注意: 这与 niri 侧 config.kdl 中的 clipboard { disable-primary } 语义上矛盾,
    # 若确认不需要主选区 (中键粘贴), 建议改成模块推荐值 "regular"。
    clipboardType = "both";
  };

  services.cliphist = {
    enable = true;
    # 保持改动前行为: 不传参数, 用 cliphist 自身的默认值
    # (cliphist 0.7.0: -max-items 750, -max-dedupe-search 100);
    # HM 模块的默认值是 500 / 10。
    extraOptions = [ ];
  };

  # wl-clipboard 仍需显式安装: niri 的剪贴板历史绑定
  # (cliphist list | fzf | cliphist decode | wl-copy) 直接调用 wl-copy,
  # 而 services.cliphist 只把 wl-clipboard 用作服务自身的可执行文件。
  home.packages = [ pkgs.wl-clipboard ];
}
