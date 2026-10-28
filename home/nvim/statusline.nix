{lib, ...}: {
  programs.nvf.settings.vim.statusline = {
    lualine = {
      enable = true;
      # vim-tpipeline hands the statusline over to tmux, whose status bar is
      # `bg=default`. lualine's `auto` theme takes section c's background from
      # the StatusLine highlight (compline leaves it at nvim's default grey),
      # so the b -> c powerline separator gets drawn on a grey cell that tmux
      # never continues -- a stray rectangle around the arrow. Make section c
      # transparent so the separator tapers straight into the tmux background.
      setupOpts.options.theme = lib.generators.mkLuaInline ''
        (function()
          local theme = vim.deepcopy(require("lualine.themes.auto"))
          for _, mode in pairs(theme) do
            if mode.c then
              mode.c.bg = "NONE"
            end
          end
          return theme
        end)()
      '';
      setupOpts.sections = {
        lualine_a = [
          {
            "@1" = "mode";
            icons_enabled = true;
          }
        ];
        lualine_b = [
          {
            "@1" = "filetype";
            colored = true;
            icon_only = true;
            icon = {align = "left";};
          }
          {
            "@1" = "filename";
            symbols = {
              modified = "●";
              readonly = "";
            };
          }
        ];
        lualine_c = [];
        lualine_x = [
          {
            "@1" = "diff";

            colored = true;
            symbols = {
              added = "+";
              modified = "~";
              removed = "-";
            };
          }
        ];
        lualine_y = [
          {
            "@1" = "branch";
            icon = "•";
          }
        ];
        lualine_z = [];
      };
      setupOpts.inactive_sections = {
        lualine_c = ["filename"];
        lualine_x = [];
      };
    };
  };
}
