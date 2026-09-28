{lib, ...}: {
  programs.nvf.settings.vim.notes = {
    todo-comments.enable = true;
    obsidian = {
      enable = true;
      setupOpts = {
        workspaces = [
          {
            name = "Obsidian";
            path = "~/Obsidian";
          }
        ];
        legacy_commands = false;
        note_id_func =
          lib.generators.mkLuaInline
          ''
            function(title)
              return title
            end
          '';
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
