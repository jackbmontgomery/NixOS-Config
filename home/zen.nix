{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    profiles = {
      default = {
        settings = {
          "layout.css.devPixelsPerPx" = "1.2";
        };
      };
    };
  };

  stylix.targets.zen-browser.profileNames = [ "default" ];
}
