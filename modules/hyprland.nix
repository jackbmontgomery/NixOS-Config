{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;

  # From unstable: 26.05 ships 0.55.4, which cannot re-enable a disabled
  # output (hyprwm/Hyprland#14496). Fixed by PR #14547, first released in
  # 0.56.0. Keep the portal on the same version as the compositor.
  programs.hyprland.package = pkgs.unstable.hyprland;
  programs.hyprland.portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
}
