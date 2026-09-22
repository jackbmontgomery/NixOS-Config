{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./keymaps.nix
    ./autocmds.nix
    ./lsp.nix
    ./notes.nix
    ./languages.nix
  ];
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
      clipboard = {
        enable = true;
        registers = "unnamedplus";
      };
      undoFile.enable = true;
      opts = {
        tabstop = 4;
        softtabstop = 4;
        shiftwidth = 4;
        expandtab = true;
        showmode = false;
        breakindent = true;
      };
      autopairs.nvim-autopairs.enable = true;
      diagnostics = {
        enable = true;
        nvim-lint = {
          enable = true;
          lint_after_save = true;
        };
      };
      autocomplete = {
        blink-cmp = {
          enable = true;
          friendly-snippets.enable = true;
        };
      };
      telescope.enable = true;
      statusline = {
        lualine = {
          enable = true;
        };
      };
      ui = {
        noice.enable = true;
      };
      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };
      utility.oil-nvim.enable = true;
      navigation = {
        harpoon.enable = true;
      };
    };
  };
}
