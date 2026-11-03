{pkgs, ...}: {
  services.hypridle = {
    enable = true;

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
