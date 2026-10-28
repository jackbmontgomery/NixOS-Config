{pkgs, ...}: {
  services.hypridle = {
    enable = true;

    # `hyprctl dispatch dpms on` is legacy-parser syntax and fails outright
    # under the lua config with: ')' expected near 'on'. It has to be dispatched
    # as lua. hyprctl also comes from the same hyprland as the running
    # compositor (unstable), not the 26.05 one.
    #
    # The argument MUST be a table: `hl.dsp.dpms({ action = "on" })`. A bare
    # string is NOT a parse error -- Internal::tableToggleAction() returns
    # TOGGLE_ACTION_TOGGLE for any non-table arg, so `hl.dsp.dpms("on")`
    # silently means "toggle" and hyprctl still answers `ok`. That made
    # after_sleep_cmd blank the panel on resume (it was already on, so the
    # toggle turned it off) with no way back in but a hard power cycle.
    settings = let
      hyprctl = "${pkgs.unstable.hyprland}/bin/hyprctl";
      dpms = state: "${hyprctl} dispatch 'hl.dsp.dpms({ action = \"${state}\" })'";
    in {
      general = {
        lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = dpms "on";
      };

      listener = [
        {
          timeout = 150;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        {
          timeout = 240;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 270;
          on-timeout = dpms "off";
          on-resume = dpms "on";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
