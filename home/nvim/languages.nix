{...}: {
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      presets = {
        harper.enable = true;
      };
      # Everything keeps its stock <leader>l* key. The six requests that can
      # return more than one result are unbound here and re-bound to those same
      # keys as Telescope pickers in default.nix, so the keys you press do not
      # change -- only the UI that answers them does.
      mappings = {
        goToDefinition = null; # -> telescope, <leader>lgd
        goToType = null; # -> telescope, <leader>lgt
        listImplementations = null; # -> telescope, <leader>lgi
        listReferences = null; # -> telescope, <leader>lgr
        listDocumentSymbols = null; # -> telescope, <leader>lS
        listWorkspaceSymbols = null; # -> telescope, <leader>lws
      };
      servers = {
        basedpyright.settings.basedpyright.analysis = {
          typeCheckingMode = "standard";
        };
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
        lsp.servers = ["basedpyright" "ruff"];
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

  programs.ruff = {
    enable = true;
    settings = {
      lint = {
        unfixable = ["F401"];
      };
    };
  };
}
