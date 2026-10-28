{
  config,
  pkgs,
  lib,
  ...
}: {
  gtk = {
    enable = true;

    # Icon Configuration
    iconTheme = {
      name = "Colloid-Dark";
      package = pkgs.colloid-icon-theme;
    };

    # Extra config for GTK 3
    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = 0;
      gtk-menu-images = 0;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };

    # Extra config for GTK 4
    gtk4.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = 0;
      gtk-menu-images = 0;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
  };

  # GTK persists the file chooser's last window size here and reopens at it
  # verbatim, so resizing the picker on a roomier display leaves a size the
  # laptop panel can't fit and the dialog hangs off the bottom edge. eDP-1
  # leaves 1010px of usable height (1080 - 56 reserved for waybar - gaps and
  # borders), so anything taller than that overflows. Re-assert a size that
  # fits on every switch.
  dconf.settings."org/gtk/settings/file-chooser".window-size =
    lib.hm.gvariant.mkTuple [(lib.gvariant.mkInt32 960) (lib.gvariant.mkInt32 900)];

  fonts.fontconfig.enable = false;
}
