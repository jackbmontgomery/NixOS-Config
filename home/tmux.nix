{
  config,
  pkgs,
  ...
}: {
  stylix.targets.tmux.enable = true;

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";

    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 1000000;
    focusEvents = true;
    keyMode = "vi";
    mouse = true;
    customPaneNavigationAndResize = true;
    shortcut = "space";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g status-right ""
          # set -g @continuum-restore 'on'
        '';
      }
    ];

    extraConfig = ''
      # True colour
      set -ga terminal-overrides ",*256col*:Tc"

      # General
      set -g set-clipboard on
      set -g detach-on-destroy off
      set -g status-interval 3
      set -g allow-passthrough on
      set -g renumber-windows on

      # Status bar layout
      set-option -g status-position top
      set -g status-justify centre

      # Reload config
      unbind r
      bind r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display "Config reloaded"

      # Copy mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
      unbind -T copy-mode-vi MouseDragEnd1Pane
      bind P paste-buffer
    '';
  };
}
