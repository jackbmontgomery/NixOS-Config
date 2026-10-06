{
  config,
  pkgs,
  ...
}: let
  c = config.lib.stylix.colors.withHashtag;
in {
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
      # absolute-centre keeps the window list from shifting as the embedded
      # nvim statusline changes width.
      set -g status-justify absolute-centre

      set -g status-style bg=default
      set -g status-left-length 99
      set -g status-right-length 99
      set -g status-left '#(cat #{socket_path}-\#{session_id}-vimbridge)'
      set -g status-right '#(cat #{socket_path}-\#{session_id}-vimbridge-R) #S '

      setw -g window-status-separator "  "
      setw -g window-status-format "#[fg=${c.base03},bg=default]#W"
      setw -g window-status-current-format "#[fg=${c.base0A},bg=default,bold]#W"
      setw -g window-status-last-style "fg=${c.base04},bg=default"

      set -g message-style "bg=default,fg=${c.base05}"
      set -g message-command-style "bg=default,fg=${c.base05}"
      set -g mode-style "bg=${c.base02},fg=${c.base05}"

      set -g pane-border-style "fg=${c.base01},bg=default"
      set -g pane-active-border-style "fg=${c.base0A},bg=default"

      unbind r
      bind r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display "Config reloaded"

      bind c new-window -c "#{pane_current_path}"

      # Copy mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
      unbind -T copy-mode-vi MouseDragEnd1Pane
      bind P paste-buffer
    '';
  };
}
