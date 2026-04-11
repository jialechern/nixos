{ config, pkgs, ... }:

{
  imports = [
    ./dev/git.nix
    ./dev/opencode.nix
    ./dev/lazygit.nix
    ./dev/haskell.nix
    ./dev/python.nix
    ./dev/nodejs.nix
  ];

  # --- --- --- 其它开发环境相关的程序 --- --- ---
  home.packages = with pkgs; [
    # Scheme 解释器
    guile
    # 系统调用的 trace 工具
    strace
    # --- 开发必备工具链 ---
    gcc # 提供 C 编译器 (cc, gcc)
    gdb # 调试器
    gnumake # 很多插件编译时需要用到 make
    binutils # 提供 ld, ar 等二进制工具
    deno # JS/TS 工具兼运行时
  ];
}
