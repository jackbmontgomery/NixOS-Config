{lib, ...}: {
  programs.nvf.settings.vim.keymaps = [
    {
      key = "-";
      mode = "n";
      silent = true;
      action = "<CMD>Oil<CR>";
      desc = "Open Parent Directory";
    }
    {
      key = "<Esc>";
      mode = "n";
      silent = true;
      action = "<cmd>nohlsearch<CR>";
      desc = "Clear search";
    }
    {
      key = "<leader>on";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          vim.ui.input({ prompt = "Note title: " }, function(title)
            if title and title ~= "" then
              vim.cmd("Obsidian new " .. title)
            end
          end)
        end
      '';
      desc = "[O]bsidian new [n]ote";
    }
    {
      key = "<leader>op";
      mode = "n";
      silent = true;
      lua = true;
      action = ''
        function()
          vim.ui.input({ prompt = "Name: " }, function(name)
            if name and name ~= "" then
              vim.cmd("Obsidian new People/" .. name)
            end
          end)
        end
      '';
      desc = "[O]bsidian new [p]erson";
    }
  ];
}
