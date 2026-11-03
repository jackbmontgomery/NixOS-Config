{
  config,
  pkgs,
  lib,
  ...
}: let
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
  mo = pkgs.writeShellScriptBin "mo" ''
    set -euo pipefail
    if [ "$#" -lt 1 ]; then
        echo "usage: mo <notebook.py>" >&2
        exit 1
    fi
    case "$1" in
        *.py) ;;
        *)
            echo "mo: name must end in .py" >&2
            exit 1
            ;;
    esac
    file="$(${pkgs.coreutils}/bin/realpath -m "$1")"
    dir="$(${pkgs.coreutils}/bin/dirname "$file")"

    project=""
    probe="$dir"
    while [ "$probe" != "/" ]; do
        if [ -f "$probe/pyproject.toml" ]; then
            project="$probe"
            break
        fi
        probe="$(${pkgs.coreutils}/bin/dirname "$probe")"
    done

    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    if [ -z "$project" ]; then
        (cd "$dir" && ${lib.getExe config.programs.uv.package} init --vcs none --bare --quiet)
        project="$dir"
        echo "mo: created uv project $project"
    fi
    if [ ! -d "$project/.venv" ]; then
        (cd "$project" && ${lib.getExe config.programs.uv.package} venv --quiet)
        echo "mo: created $project/.venv"
    fi

    if [ ! -s "$file" ]; then
        {
            ${pkgs.coreutils}/bin/printf -- 'import marimo\n\napp = marimo.App()\n\n\n'
            ${pkgs.coreutils}/bin/printf -- '@app.cell\ndef _():\n    return\n\n\n'
            ${pkgs.coreutils}/bin/printf -- 'if __name__ == "__main__":\n    app.run()\n'
        } > "$file"
        echo "mo: scaffolded $file"
    fi
    exec ${config.programs.vscode.package}/bin/code "$project" "$file"
  '';
in {
  home.packages = [
    wofi-open
    mo
    mic-led-sync
    osd-brightness
    osd-volume
    lock-screen
    power-off
  ];

  home.file."Wallpapers".source = ../wallpapers;
}
