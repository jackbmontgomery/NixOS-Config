{...}: {
  programs.ruff = {
    enable = true;
    settings = {
      lint = {
        unfixable = ["F401"];
      };
    };
  };

  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      presets = {
        harper.enable = true;
      };
    };
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      markdown = {
        enable = true;
        lsp.servers = ["rumdl"];
        format.type = ["rumdl"];
      };
      lua.enable = true;
      python = {
        enable = true;
        format.type = ["ruff" "ruff-fix"];
        lsp.servers = ["ty" "ruff"];
        extraDiagnostics.enable = false;
      };
    };
    formatter.conform-nvim.setupOpts.formatters.rumdl.append_args = [
      "--config"
      ''global.flavor = "obsidian"''
      "--config"
      "MD013.line-length = 80"
      "--config"
      "MD013.reflow = true"
      "--config"
      ''MD013.reflow-mode = "normalize"''
    ];
  };
}
