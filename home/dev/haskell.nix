{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # 核心编译器与解释器
    ghc

    # 构建工具
    cabal-install
    stack

    # Lint
    hlint

    # 搜索与实时反馈
    haskellPackages.hoogle
    ghcid
  ];
}
