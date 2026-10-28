{
  pkgs,
  lib,
  ...
}: let
  compline-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "compline-nvim";
    version = "0-unstable-2026-10-22";

    src = pkgs.fetchFromGitHub {
      owner = "joshuablais";
      repo = "compline";
      rev = "38c00bc603a908b57f1d7f0b516dc8945c21d40b";
      hash = "sha256-LYs9yn1hsyctL5sEIdbcHymUTf8q4yrucfqgvGKZG6M=";
    };

    sourceRoot = "source/nvim";

    postPatch = ''
      mkdir -p lua
      mv compline lauds lua/
    '';
  };

  colorscheme = "compline";
in {
  programs.nvf.settings.vim = {
    theme.enable = lib.mkForce false;

    startPlugins = [compline-nvim];
    luaConfigRC.compline = {
      data = ''vim.cmd("colorscheme ${colorscheme}")'';
      after = [];
      before = ["pluginConfigs" "lazyConfigs"];
    };
  };
}
