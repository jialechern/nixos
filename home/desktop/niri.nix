{ config, pkgs, lib, inputs, ... }:

{
  xdg.configFile."niri" = {
    source = inputs.niri-dotfiles;
    recursive = true;
  };
}
