{
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
  };

  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
      clipboard.enable = true;
      lsp = {
        enable = true;
        formatOnSave = true;
      };
      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        nix.enable = true;
        markdown.enable = true;
        lua.enable = true;
        python.enable = true;
      };
      autocomplete = {
        blink-cmp.enable = true;
      };
      telescope.enable = true;
    };
  };
}
