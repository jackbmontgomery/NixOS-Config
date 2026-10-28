{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./home/gtk.nix
    ./home/zsh.nix
    ./home/thunar.nix
    ./home/hyprland.nix
    ./home/kitty.nix
    ./home/waybar.nix
    ./home/scripts.nix
    ./home/wofi.nix
    ./home/desktop-entries.nix
    ./home/hypridle.nix
    ./home/hyprlock.nix
    ./home/dunst.nix
    ./home/python.nix
    ./home/zen.nix
    ./home/git.nix
    ./home/obsidian.nix
    ./home/tmux.nix
    ./home/tex.nix
    ./home/zathura.nix
    ./home/vscode.nix
    ./home/pluto.nix
    ./home/nvim
  ];

  home = {
    username = "jbm";
    homeDirectory = "/home/jbm";
    stateVersion = "26.05";
  };
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.colloid-icon-theme
    pkgs.pavucontrol
    pkgs.networkmanagerapplet
    pkgs.libnotify
    pkgs.hyprshot
    pkgs.hyprpicker
    pkgs.zotero
    pkgs.ripgrep
    pkgs.speedtest-go
    pkgs.claude-code
  ];
  programs.imv = {
    enable = true;
    settings = {
      options = {
        overlay = true;
        overlay_text = "[\${imv_current_index}/\${imv_file_count}] \${imv_current_file##*/}";
      };
    };
  };
}
