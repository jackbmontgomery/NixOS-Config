{lib, ...}: {
  programs.nvf.settings.vim = {
    augroups = [
      {name = "jbm";}
    ];
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
      {
        event = ["ColorScheme"];
        pattern = ["*"];
        group = "jbm";
        desc = "Keep laststatus=0 while vim-tpipeline owns the statusline";
        callback = lib.generators.mkLuaInline ''
          function()
              -- Deferred so it lands after lualine's handler regardless of
              -- which autocmd was registered first.
              vim.schedule(function()
                if vim.g.loaded_tpipeline == 1 then
                  vim.o.laststatus = 0
                end
              end)
          end
        '';
      }
      {
        event = ["OptionSet"];
        pattern = ["background"];
        group = "jbm";
        desc = "Keep laststatus=0 after a background flip reloads lualine";
        callback = lib.generators.mkLuaInline ''
          function()
              vim.schedule(function()
                if vim.g.loaded_tpipeline == 1 then
                  vim.o.laststatus = 0
                end
              end)
          end
        '';
      }
    ];
  };
}
