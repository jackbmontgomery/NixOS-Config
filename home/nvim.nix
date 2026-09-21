{
  config,
  pkgs,
  lib,
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
      clipboard = {
        enable = true;
        registers = "unnamedplus";
      };
      opts = {
        tabstop = 4;
        softtabstop = 4;
        shiftwidth = 4;
        expandtab = true;
        showmode = false;
        breakindent = true;
      };
      keymaps = [
        {
          key = "-";
          mode = "n";
          silent = true;
          action = "<CMD>Oil<CR>";
          desc = "Open Parent Directory";
        }
      ];
      augroups = [{name = "jbm";}];
      autocmds = [
        {
          event = ["TextYankPost"];
          group = "jbm";
          desc = "Highlight when yanking text";
          callback = lib.generators.mkLuaInline ''
            function()
                vim.highlight.on_yank()
            end
          '';
        }
      ];
      autopairs.nvim-autopairs.enable = true;
      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        nix.enable = true;
        markdown.enable = true;
        lua.enable = true;
        python.enable = true;
      };
      lsp = {
        enable = true;
        formatOnSave = true;
      };
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
      notes = {
        todo-comments.enable = true;
      };
    };
  };
}
