{
  config,
  pkgs,
  lib,
  ...
}:
let
  wofi-open = pkgs.writeShellScriptBin "wofi-open" ''
    exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/wofi.lock"
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
        exit 0
    fi
    exec ${pkgs.wofi}/bin/wofi --show drun
  '';

  mic-led-sync = pkgs.writeShellScriptBin "mic-led-sync" ''
    set -euo pipefail
    LED="/sys/class/leds/platform::micmute/brightness"
    out="$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>&1 || true)"
    echo 0 > "$LED"
    if [[ "$out" == *"Could not connect to PipeWire"* ]]; then
        echo "mic-led-sync: PipeWire not reachable in this session." >&2
        exit 1
    fi
    if [[ "$out" == *"No such"* ]] || [[ "$out" == *"Unknown"* ]]; then
        echo "mic-led-sync: no valid DEFAULT_AUDIO_SOURCE. Output: $out" >&2
        exit 1
    fi
    if echo "$out" | ${pkgs.gnugrep}/bin/grep -q "MUTED"; then
        echo 1 > "$LED"
    else
        echo 0 > "$LED"
    fi
  '';

  osd-brightness = pkgs.writeShellScriptBin "osd-brightness" ''
    step="5%"
    case "$1" in
        up)
            ${pkgs.brightnessctl}/bin/brightnessctl set +"$step" >/dev/null
            ;;
        down)
            ${pkgs.brightnessctl}/bin/brightnessctl set "$step"- >/dev/null
            ;;
    esac
    br="$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.gawk}/bin/awk -F, '{gsub("%","",$4); print $4}')"
  '';

  osd-volume = pkgs.writeShellScriptBin "osd-volume" ''
    sink="@DEFAULT_AUDIO_SINK@"
    step="5%"
    case "$1" in
        up)
            ${pkgs.wireplumber}/bin/wpctl set-mute "$sink" 0
            ${pkgs.wireplumber}/bin/wpctl set-volume -l 1 "$sink" "$step+"
            ;;
        down)
            ${pkgs.wireplumber}/bin/wpctl set-mute "$sink" 0
            ${pkgs.wireplumber}/bin/wpctl set-volume "$sink" "$step-"
            ;;
        mute)
            ${pkgs.wireplumber}/bin/wpctl set-mute "$sink" toggle
            ;;
    esac
    state="$(${pkgs.wireplumber}/bin/wpctl get-volume "$sink")"
    vol="$(${pkgs.gawk}/bin/awk '{printf "%d", $2 * 100}' <<< "$state")"
  '';

  lock-screen = pkgs.writeShellScriptBin "lock-screen" ''
    exec ${pkgs.hyprlock}/bin/hyprlock
  '';

  power-off = pkgs.writeShellScriptBin "power-off" ''
    exec ${pkgs.systemd}/bin/systemctl poweroff
  '';
in
{
  home.packages = [
    wofi-open
    mic-led-sync
    osd-brightness
    osd-volume
    lock-screen
    power-off
  ];

  home.file."Wallpapers".source = ../wallpapers;
}
