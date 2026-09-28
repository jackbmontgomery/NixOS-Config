{
  config,
  lib,
  pkgs,
  ...
}: {
  stylix = {
    enable = true;
    image = ../wallpapers/night.jpg;
    polarity = "dark";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 18;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 16;
        applications = 14;
        desktop = 16;
        popups = 16;
      };
    };

    opacity = {
      terminal = 0.9;
      popups = 0.8;
    };
  };
}
