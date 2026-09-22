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
    ];
  };
}
