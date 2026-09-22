{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nvim/default.nix
  ];
  programs.neovim = {
    enable = true;
  };

  programs.nvf.enable = true;
}
