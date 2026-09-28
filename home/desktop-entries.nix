{
  config,
  pkgs,
  lib,
  ...
}: let
  hidden = name: {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=${name}
      NoDisplay=true
    '';
  };
in {
  # Hide unwanted launcher entries by overriding them in the user's
  # applications dir (~/.local/share/applications), which takes precedence.

  xdg.dataFile = {
    "applications/kitty-open.desktop" = hidden "kitty URL Launcher";
    "applications/org.freedesktop.Xwayland.desktop" = hidden "Xwayland";
    "applications/xdg-desktop-portal-gtk.desktop" = hidden "Portal";
    "applications/nixos-manual.desktop" = hidden "NixOS Manual";
    "applications/uuctl.desktop" = hidden "uuctl";
    "applications/nvim.desktop" = hidden "Neovim wrapper";
    "applications/vim.desktop" = hidden "Vim wrapper";
    "applications/nm-applet.desktop" = hidden "NetworkManager Applet";
    "applications/nm-connection-editor.desktop" = hidden "Advanced Network Configuration";
    "applications/blueman-adapters.desktop" = hidden "Bluetooth Adapters";
    "applications/blueman-manager.desktop" = hidden "Bluetooth Manager";
    "applications/org.pulseaudio.pavucontrol.desktop" = hidden "Volume Control";
    "applications/thunar-bulk-rename.desktop" = hidden "Bulk Rename";
    "applications/thunar-settings.desktop" = hidden "Thunar Preferences";
    "applications/thunar-volman-settings.desktop" = hidden "Removable Drives and Media";

    # Qt theming tools (pulled in by Stylix)
    "applications/kvantummanager.desktop" = hidden "Kvantum Manager";
    "applications/qt5ct.desktop" = hidden "Qt5 Settings";
    "applications/qt6ct.desktop" = hidden "Qt6 Settings";

    # KiCad
    "applications/org.kicad.bitmap2component.desktop" = hidden "KiCad Bitmap2Component";
    "applications/org.kicad.eeschema.desktop" = hidden "KiCad Eeschema";
    "applications/org.kicad.gerbview.desktop" = hidden "KiCad Gerbview";
    "applications/org.kicad.pcbcalculator.desktop" = hidden "KiCad PCB Calculator";
    "applications/org.kicad.pcbnew.desktop" = hidden "KiCad PCBNew";
  };
}
