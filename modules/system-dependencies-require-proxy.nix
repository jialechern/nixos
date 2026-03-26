{ config, lib, pkgs, ... }:

{
  # --- 字体配置 ---
  fonts.packages = with pkgs; [
    wqy_zenhei
  ];
}
