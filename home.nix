{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./home/gtk.nix
    ./home/nvim.nix
    ./home/zsh.nix
    ./home/thunar.nix
    ./home/hyprland.nix
    ./home/kitty.nix
    ./home/waybar.nix
    ./home/scripts.nix
    ./home/wofi.nix
    ./home/desktop-entries.nix
    ./home/awww.nix
    ./home/hypridle.nix
    ./home/hyprlock.nix
    ./home/dunst.nix
    ./home/python.nix
    ./home/zen.nix
    ./home/vscode.nix
    ./home/git.nix
    ./home/obsidian.nix
  ];

  home.username = "jbm";
  home.homeDirectory = "/home/jbm";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.colloid-icon-theme
    pkgs.poppins
    pkgs.pavucontrol
    pkgs.networkmanagerapplet
    pkgs.libnotify
    pkgs.awww
    pkgs.hyprshot
    pkgs.hyprpicker
  ];
}
