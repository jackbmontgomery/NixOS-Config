{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./keymaps.nix
    ./autocmds.nix
    ./notes.nix
    ./languages.nix
    ./utility.nix
    ./statusline.nix
  ];
  stylix.targets.neovim.enable = false;
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
        ignorecase = true;
        smartcase = true;
        conceallevel = 1;
        foldlevel = 99;
        foldenable = true;
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
      telescope = {
        enable = true;
        mappings = {
          lspDefinitions = "<leader>lgd";
          lspTypeDefinitions = "<leader>lgt";
          lspImplementations = "<leader>lgi";
          lspReferences = "<leader>lgr";
          lspDocumentSymbols = "<leader>lS";
          lspWorkspaceSymbols = "<leader>lws";
        };
      };
      extraPlugins.vim-tpipeline.package = pkgs.vimPlugins.vim-tpipeline;

      globals = {
        tpipeline_autoembed = 0;
        tpipeline_restore = 0;
        tpipeline_cursormoved = 0;
      };

      ui = {
        noice.enable = true;
      };
      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };
      terminal.toggleterm = {
        enable = true;
        mappings.open = "<leader>tt";
        setupOpts = {
          direction = "float";
        };
      };
      navigation = {
        harpoon = {
          enable = true;
          mappings = {
            file1 = "<leader>1";
            file2 = "<leader>2";
            file3 = "<leader>3";
            file4 = "<leader>4";
          };
        };
      };
      dashboard.dashboard-nvim.enable = true;
    };
  };
}
