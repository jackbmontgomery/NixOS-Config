{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    localBinInPath = true;
    systemPackages = with pkgs; [
      wev
      wget
      git
      unzip
      lxqt.lxqt-policykit
      fastfetch
      btop
      brightnessctl
      playerctl
      trash-cli
      sound-theme-freedesktop
      ripgrep
      wl-clipboard
      vim
    ];
  };
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
  ];
}
