{lib, ...}: {
  programs.nvf.settings.vim.notes = {
    todo-comments.enable = true;
    obsidian = {
      enable = true;

      setupOpts = {
        workspaces = [
          {
            name = "Jack Montgomery";
            path = "~/Documents/Obsidian/Jack Montgomery";
          }
        ];
        legacy_commands = false;

        note_id_func =
          lib.generators.mkLuaInline
          ''require("obsidian.builtin").title_id'';
        templates = {
          folder = "Templates";
        };
        note = {
          template = "default.md";
        };
      };
    };
  };
}
