{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./home/gtk.nix
    ./home/zsh.nix
    ./home/thunar.nix
    ./home/hyprland.nix
    ./home/kitty.nix
    ./home/waybar.nix
    ./home/scripts.nix
    ./home/wofi.nix
    ./home/desktop-entries.nix
    ./home/hypridle.nix
    ./home/hyprlock.nix
    ./home/dunst.nix
    ./home/python.nix
    ./home/zen.nix
    ./home/git.nix
    ./home/obsidian.nix
    ./home/tmux.nix
    ./home/tex.nix
    ./home/zathura.nix
    ./home/vscode.nix
    # Back, on the second of the two terms this comment set out when it was
    # removed. The original removal, kept verbatim below, ended: "Re-enabling
    # means accepting that cost again, or pinning every notebook with
    # `Pkg.activate()` in its first cell -- Pluto disables its built-in package
    # management when it sees that, and uses the project env instead."
    #
    # That pinning is now the default rather than a thing to remember: `pl`
    # scaffolds the activation cell into every notebook it creates, and opens
    # the project root as the workspace. With a project above the notebook the
    # cell joins it; with none, it activates the notebook's own directory, so
    # that folder becomes the environment on the first Pkg.add -- the
    # per-folder sandbox, reached without having to set it up. Measured on
    # throwaway notebooks in both layouts: `Pluto.use_plutopkg` false, i.e.
    # Pluto's package manager off. So no scratchspace env is created for a
    # scaffolded notebook at all, and the ~20-minute-per-notebook SciML
    # rebuild below cannot recur.
    #
    # It can still recur for a notebook *without* the cell, which was measured
    # the hard way: deleting the activation cell from a working notebook had
    # Pluto build two environments within half an hour, the second with 259
    # packages at tilde compat against the project's caret.
    #
    # The other half of the reason to take it back is new: JETLS serves Pluto
    # notebook cells now, which is the whole point of the arrangement and is
    # what the patch in home/nvim/jetls-pluto-notebook.patch buys. A notebook
    # that shares the project's environment is also the only kind any language
    # server can resolve -- Pluto's built-in manager keeps the environment
    # inside the notebook file and materialises it into a scratch mktempdir,
    # so there is nothing on disk to resolve against.
    #
    # Still accepted, unchanged: the extension bootstraps its own
    # ~/.julia/environments/vscode_pluto_notebook env on every launch, and
    # pulls in julialang.language-julia and the juliahub auth extension as
    # hard extensionDependencies.
    #
    # The original removal note:
    #
    # > Removed: the Pluto VS Code extension gives every notebook its own
    # > package environment (9 of them accumulated under
    # > ~/.julia/scratchspaces/<Pluto-uuid>/pkg_envs, with 276/272/152-package
    # > manifests), and it pins with tilde compat (OrdinaryDiffEq = "~7.8.1")
    # > where the project environments use caret, so those resolutions can
    # > never share a precompile cache with ~/UCT/sandbox. Each notebook was a
    # > separate ~20-minute build of the same SciML tree. The extension also
    # > bootstraps its own ~/.julia/environments/vscode_pluto_notebook env on
    # > every launch.
    # >
    # > It also brought julialang.language-julia and the juliahub auth
    # > extension, whose VSCodeServer showed up in the precompile logs for the
    # > same reason.
    ./home/pluto.nix
    ./home/julia.nix
    ./home/nvim
  ];

  home = {
    username = "jbm";
    homeDirectory = "/home/jbm";
    stateVersion = "26.05";
  };
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.colloid-icon-theme
    pkgs.pavucontrol
    pkgs.networkmanagerapplet
    pkgs.libnotify
    pkgs.hyprshot
    pkgs.hyprpicker
    pkgs.zotero
    pkgs.ripgrep
    pkgs.speedtest-go
    pkgs.claude-code
  ];
  programs.imv = {
    enable = true;
    settings = {
      options = {
        overlay = true;
        overlay_text = "[\${imv_current_index}/\${imv_file_count}] \${imv_current_file##*/}";
      };
    };
  };
}
