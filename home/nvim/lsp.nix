{...}: {
  programs.nvf.settings.vim.lsp = {
    enable = true;
    formatOnSave = true;
    presets = {
      harper.enable = true;
    };
  };
}
