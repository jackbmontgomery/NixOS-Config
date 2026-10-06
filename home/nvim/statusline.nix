{lib, ...}: {
  programs.nvf.settings.vim.statusline = {
    lualine = {
      enable = true;
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
