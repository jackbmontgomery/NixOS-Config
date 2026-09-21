{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
}
