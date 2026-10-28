{
  config,
  pkgs,
  lib,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";
    settings = let
      lua = lib.generators.mkLuaInline;
      bind = key: action: {
        _args = [
          key
          (lua action)
        ];
      };
      bindo = key: action: opts: {
        _args = [
          key
          (lua action)
          (lua opts)
        ];
      };
      exec = cmd: ''hl.dsp.exec_cmd("${cmd}")'';
      ws = n: ''hl.dsp.focus({ workspace = "${n}" })'';
      mvws = n: ''hl.dsp.window.move({ workspace = "${n}" })'';
      resizeStep = 40;
      resize = x: y: let
        px = n: toString (n * resizeStep);
      in ''hl.dsp.window.resize({ x = ${px x}, y = ${px y}, relative = true })'';
    in {
      bind = [
        # Apps
        (bind "SUPER + T" (exec "kitty"))
        (bind "SUPER + B" (exec "zen-beta"))
        (bind "SUPER + N" (exec "obsidian"))
        (bind "SUPER + E" (exec "thunar"))

        (bind "SUPER + Space" (exec "wofi-open"))

        (bind "SUPER + ALT + Return" (exec "lock-screen"))
        (bind "CTRL + SUPER + ALT + Return" (exec "uwsm stop"))

        # Window management
        (bind "SUPER + Q" "hl.dsp.window.close()")

        # Special Workspace
        (bind "SUPER + Return" "hl.dsp.workspace.toggle_special()")
        (bind "SUPER + SHIFT + Return" ''hl.dsp.window.move({ workspace = "special" })'')

        # Move focus
        (bind "SUPER + ALT + H" ''hl.dsp.focus({ direction = "left" })'')
        (bind "SUPER + ALT + L" ''hl.dsp.focus({ direction = "right" })'')
        (bind "SUPER + ALT + K" ''hl.dsp.focus({ direction = "up" })'')
        (bind "SUPER + ALT + J" ''hl.dsp.focus({ direction = "down" })'')

        # Resize window
        (bindo "SUPER + SHIFT + ALT + H" (resize (-1) 0) "{ repeating = true }")
        (bindo "SUPER + SHIFT + ALT + L" (resize 1 0) "{ repeating = true }")
        (bindo "SUPER + SHIFT + ALT + K" (resize 0 (-1)) "{ repeating = true }")
        (bindo "SUPER + SHIFT + ALT + J" (resize 0 1) "{ repeating = true }")

        # Workspaces
        (bind "SUPER + J" (ws "1"))
        (bind "SUPER + K" (ws "2"))
        (bind "SUPER + L" (ws "3"))
        (bind "SUPER + semicolon" (ws "4"))

        # Move window to workspace
        (bind "SUPER + SHIFT + J" (mvws "1"))
        (bind "SUPER + SHIFT + K" (mvws "2"))
        (bind "SUPER + SHIFT + L" (mvws "3"))
        (bind "SUPER + SHIFT + semicolon" (mvws "4"))

        # Volume
        (bindo "XF86AudioRaiseVolume" (exec "osd-volume up") "{ locked = true, repeating = true }")
        (bindo "XF86AudioLowerVolume" (exec "osd-volume down") "{ locked = true, repeating = true }")
        (bindo "XF86AudioMute" (exec "osd-volume mute") "{ locked = true }")
        (
          bindo "XF86AudioMicMute"
          (exec "sh -c 'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; mic-led-sync'")
          "{ locked = true }"
        )

        # Brightness
        (bindo "XF86MonBrightnessUp" (exec "osd-brightness up") "{ locked = true, repeating = true }")
        (bindo "XF86MonBrightnessDown" (exec "osd-brightness down") "{ locked = true, repeating = true }")

        # Multimedia keys
        (bindo "SUPER + PRINT" (exec "hyprshot -m region -o ~/Screenshots") "{ locked = true }")
        (bindo "XF86SelectiveScreenshot" (exec "hyprshot -m region --clipboard-only") "{ locked = true }")

        (bindo "XF86AudioNext" (exec "playerctl next") "{ locked = true }")
        (bindo "XF86AudioPause" (exec "playerctl play-pause") "{ locked = true }")
        (bindo "XF86AudioPlay" (exec "playerctl play-pause") "{ locked = true }")
        (bindo "XF86AudioPrev" (exec "playerctl previous") "{ locked = true }")
      ];
    };

    extraConfig = ''
      hl.env("QT_QPA_PLATFORM", "wayland")
      hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
      hl.env("QT_STYLE_OVERRIDE", "Fusion")

      local LAPTOP = "eDP-1"
      local function laptop(disabled)
          hl.monitor({
              output = LAPTOP, mode = "preferred", position = "auto",
              scale = 1, transform = 0, disabled = disabled,
          })
      end

      hl.bind("SUPER + SHIFT + M", function() laptop(false) end)

      hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1, transform = 0 })
      hl.monitor({ output = "DP-1", mode = "1920x1080@165", position = "0x0", scale = 1, transform = 3 })

      local function external_present()
          local ok, found = pcall(function()
              for _, m in ipairs(hl.get_monitors()) do
                  local n = m.name
                  if n ~= LAPTOP
                      and not n:match("^HEADLESS")
                      and not n:match("^FALLBACK") then
                      return true
                  end
              end
              return false
          end)
          if ok then return found end
          return nil
      end

      -- Settle time before re-focusing, same order as the 300ms hotplug
      -- debounce below: the connect has to finish picking its own workspace
      -- first, otherwise it lands after us and wins.
      local RESTORE_DELAY_MS = 300

      -- Enabling a panel is a *fresh* monitor connect, and Hyprland hands a
      -- fresh monitor the lowest unused workspace id
      -- (CMonitor::findAvailableDefaultWS) unless a workspace rule names a
      -- default for it. With 1-3 in use that landed us on a newly created,
      -- empty workspace 4 after every HDMI unplug. Pinning a default would
      -- need a `monitor =` workspace rule, which this config deliberately
      -- avoids, so instead remember the workspace in use across the switch
      -- and focus it again once the panel is up.
      local function apply()
          local ext = external_present()
          if ext == nil then return end

          -- Kept as a name, not a workspace object: an empty workspace is
          -- destroyed during the switch and the object would expire with it.
          local ok, prev = pcall(function() return hl.get_active_workspace().name end)
          laptop(ext)

          -- The special workspace is toggled, not focused; restoring it as a
          -- regular workspace would be wrong.
          if not ok or type(prev) ~= "string" or prev:match("^special") then return end

          hl.timer(function()
              hl.dispatch(hl.dsp.focus({ workspace = prev }))
          end, { timeout = RESTORE_DELAY_MS, type = "oneshot" })
      end

      apply()

      local function apply_soon()
          hl.timer(apply, { timeout = 300, type = "oneshot" })
      end

      hl.on("monitor.added", apply_soon)
      hl.on("monitor.removed", apply_soon)

      hl.config({
          general =
          {
              gaps_in = 5, gaps_out = 5, border_size = 2,
              ["col.active_border"] = "rgba(78a9ffaa)", ["col.inactive_border"] = "rgba(2c2c2caa)",
              resize_on_border = true, allow_tearing = false, layout = "master"
          },

          animations = {enabled = false },

      decoration =
      {
          rounding = 10, active_opacity = 1.0, inactive_opacity = 0.7, fullscreen_opacity = 1.0,
          shadow = { enabled = true, range = 15, color = "rgba(19191966)" },
          blur = { enabled = true, size = 3, passes = 2, brightness = 0.6, contrast = 1.0, noise = 0, xray = false, popups = false }
      },

      -- *_enables_dpms: last-resort escape hatch. If anything ever leaves the
      -- panel powered off (a bad dpms dispatch, a resume race), a keypress or
      -- mouse move brings it back instead of needing a hard power cycle.
      misc = { force_default_wallpaper = 0, disable_hyprland_logo = true,
               key_press_enables_dpms = true, mouse_move_enables_dpms = true },
      input = { kb_layout = "us", kb_variant = "", kb_model = "thinkpad", follow_mouse = 1, sensitivity = 0, natural_scroll = true, touchpad = { natural_scroll = true } }
      })

      hl.device({
          name = "synps/2-synaptics-touchpad",
          sensitivity = 0.7,
      })

      hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })
      hl.curve("snappyReturn", { type = "bezier", points = { {0.4, 0.9}, {0.6, 1.0} } })
      hl.curve("bounce", { type = "bezier", points = { {0.4, 0.9}, {0.6, 1.0} } })
      hl.curve("md3_decel", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
      hl.curve("softAcDecel", { type = "bezier", points = { {0.26, 0.26}, {0.15, 1} } })

      hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
      hl.gesture({ fingers = 3, direction = "down", action = "close" })
      hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd("wofi --show drun") end })
      hl.gesture({ fingers = 4, direction = "vertical", action = function()
          hl.dispatch(hl.dsp.workspace.toggle_special())
      end })

      -- Window rules
      hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
      hl.window_rule({ name = "thunar-float", match = { class = "thunar" }, float = true, size = "1000 700", center = true })
      hl.window_rule({ name = "wifi-float", match = { class = "nm-connection-editor" }, float = true, size = "640 400", move = "1270 50" })
      hl.window_rule({ name = "bluetooth-float", match = { class = "blueman-manager" }, float = true, size = "640 400", move = "1270 50" })
      hl.window_rule({ name = "vol-float", match = { class = "org.pulseaudio.pavucontrol" }, float = true, size = "640 400", move = "1270 50" })

      -- Workspace rules
      -- Deliberately no `monitor =` pins: only one display is active at a
      -- time, so 1-3 and special follow whichever one that is.

      -- Layer rules
      hl.layer_rule({
          match = { namespace = "waybar" },
          blur = true,
          ignore_alpha = 1.0,
          order = 1,
      })

      hl.on("window.open", function(w)
          hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0, action = "set", window = w }))
      end)

      hl.on("hyprland.start", function()
          hl.exec_cmd("waybar")
          hl.exec_cmd("lxqt-policykit-agent")
          hl.exec_cmd("nm-applet --indicator")
          hl.exec_cmd("mic-led-sync")
      end)
    '';
  };
}
