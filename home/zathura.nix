{
  lib,
  pkgs,
  ...
}: {
  programs.zathura = {
    enable = true;

    options = {
      synctex = true;

      synctex-editor-command = "${lib.getExe pkgs.texlab} inverse-search -i %{input} -l %{line}";
      database = "sqlite";
    };
  };
}
