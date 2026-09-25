{...}: {
  programs.nvf.settings.vim.languages = {
    enableFormat = true;
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    nix.enable = true;
    markdown = {
      enable = true;
      format.type = ["rumdl"];
    };
    lua.enable = true;
    python = {
      enable = true;
      format.type = ["ruff" "ruff-fix"];
    };
  };
}
