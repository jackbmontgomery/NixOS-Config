{...}: {
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
  ];
}
