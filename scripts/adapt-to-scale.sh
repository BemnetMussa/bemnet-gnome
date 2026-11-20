#!/usr/bin/env bash
# Adapt dock, panel, and cursor pixel sizes to this machine's display.
# Never changes the user's display scale or text-scaling-factor — only our UI sizes.
set -euo pipefail

log()  { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

# Reference baseline: ~1080 logical-px tall (e.g. 4K @ 200%, or 1080p @ 100%)
REF_LOGICAL_H=1080
REF_TEXT_SCALE=1.25

read_geometry() {
  python3 - <<'PY'
import sys, subprocess, re

text_scale = 1.0
try:
    import gi
    gi.require_version("Gio", "2.0")
    from gi.repository import Gio
    text_scale = float(Gio.Settings.new("org.gnome.desktop.interface").get_double("text-scaling-factor"))
except Exception:
    pass

width = height = 0
layout_scale = 1.0
mode_scale = 1.0
renderer = ""

# 1. Try DBus Mutter DisplayConfig first
try:
    import gi
    gi.require_version("Gio", "2.0")
    from gi.repository import Gio

    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    proxy = Gio.DBusProxy.new_sync(
        bus, Gio.DBusProxyFlags.NONE, None,
        "org.gnome.Mutter.DisplayConfig",
        "/org/gnome/Mutter/DisplayConfig",
        "org.gnome.Mutter.DisplayConfig", None,
    )
    state = proxy.call_sync("GetCurrentState", None, Gio.DBusCallFlags.NONE, -1, None)
    serial, monitors, logical, props = state.unpack()
    renderer = str(props.get("renderer", ""))

    chosen = None
    for lm in logical:
        if len(lm) >= 5 and lm[4]:
            chosen = lm
            break
    if chosen is None and logical:
        chosen = logical[0]
    if chosen is not None:
        layout_scale = float(chosen[2]) or 1.0

    for mon in monitors:
        for mode in mon[1]:
            mprops = mode[6] if len(mode) > 6 else {}
            if mprops.get("is-current"):
                width, height = int(mode[1]), int(mode[2])
                mode_scale = float(mode[4]) or 1.0
                break
        if height:
            break
except Exception:
    pass

# 2. Fallback to xrandr on X11 if DBus did not give height
if height == 0:
    try:
        out = subprocess.check_output(["xrandr"], text=True, stderr=subprocess.DEVNULL)
        m = re.search(r'\bconnected\s+(?:primary\s+)?(\d+)x(\d+)', out)
        if m:
            width, height = int(m.group(1)), int(m.group(2))
            renderer = "xrandr-fallback"
    except Exception:
        pass

# On X11 fractional scaling, layout_scale is often 1.0 while mode_scale is 1.25/1.5/2.0.
# Prefer mode_scale when it is meaningfully larger than layout_scale.
ui_scale = mode_scale if mode_scale > layout_scale + 0.01 else layout_scale
if ui_scale <= 0:
    ui_scale = 1.0

if height > 0:
    logical_h = int(round(height / ui_scale))
    logical_w = int(round(width / ui_scale)) if width else 1920
else:
    logical_w, logical_h = 1920, 1080

print(f"{ui_scale} {text_scale} {logical_w} {logical_h} {layout_scale} {mode_scale} {renderer}")
PY
}

clamp() {
  local v="$1" lo="$2" hi="$3"
  if (( v < lo )); then echo "$lo"
  elif (( v > hi )); then echo "$hi"
  else echo "$v"
  fi
}

round_mul() {
  python3 -c "print(int(round(float('$1') * float('$2'))))"
}

main() {
  log "Adapting UI and cursor sizes to this machine's display (preserving display scale)"

  local geo ui_scale text_scale logical_w logical_h layout_scale mode_scale renderer factor
  geo="$(read_geometry)"
  ui_scale="$(echo "$geo" | awk '{print $1}')"
  text_scale="$(echo "$geo" | awk '{print $2}')"
  logical_w="$(echo "$geo" | awk '{print $3}')"
  logical_h="$(echo "$geo" | awk '{print $4}')"
  layout_scale="$(echo "$geo" | awk '{print $5}')"
  mode_scale="$(echo "$geo" | awk '{print $6}')"
  renderer="$(echo "$geo" | awk '{print $7}')"

  # Factor determines how much larger/smaller UI widgets should be relative to 1080p @ 1.25x text
  factor="$(python3 -c "
logical_h=float('$logical_h')
text=float('$text_scale')
ref_h=float('$REF_LOGICAL_H')
ref_t=float('$REF_TEXT_SCALE')
f = logical_h / ref_h
f *= max(0.85, min(1.15, text / ref_t))
print(max(0.65, min(1.45, f)))
")"

  # Calculate optimal proportional cursor size (matches standard Xcursor increments)
  local cursor_size
  cursor_size="$(python3 -c "
logical_h=float('$logical_h')
text=float('$text_scale')
# Physical pixel target based on screen height and text scaling
eff_scale = (logical_h / 1080.0) * max(1.0, text)
target_px = 24.0 * eff_scale
supported = [24, 28, 32, 36, 40, 48, 56, 64]
closest = min(supported, key=lambda x: (abs(x - target_px), -x))
print(closest)
")"

  # Fluid dock geometry & physics
  local dock_icon falloff border show_thr dash_icon panel_icon pad_btn pad_ind corner
  dock_icon="$(clamp "$(round_mul 54 "$factor")" 38 72)"
  falloff="$(clamp "$(round_mul 155 "$factor")" 100 200)"
  border="$(clamp "$(round_mul 24 "$factor")" 14 30)"
  show_thr="$(clamp "$(round_mul 25 "$factor")" 16 40)"
  dash_icon="$(clamp "$(round_mul 48 "$factor")" 32 64)"
  panel_icon="$(clamp "$(round_mul 22 "$factor")" 16 28)"
  pad_btn="$(clamp "$(round_mul 5 "$factor")" 2 10)"
  pad_ind="$(clamp "$(round_mul 6 "$factor")" 2 12)"
  corner="$border" # Perfectly align top bar blur corner radius with dock border radius

  # Keep silky magnification scale (1.48) with slight adjustment for ultra-compact displays
  local mag_scale
  mag_scale="$(python3 -c "
f=float('$factor')
print(1.40 if f < 0.8 else 1.48)
")"

  echo "  Display: logical=${logical_w}x${logical_h} (ui_scale=$ui_scale text_scale=$text_scale factor=$factor)"
  echo "  Adaptive sizes: dock_icon=${dock_icon}px  dock_radius=${border}px  falloff=${falloff}  cursor=${cursor_size}px"

  # 1. Apply Cursor Sizing across GNOME, GTK 3, GTK 4, and X11
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-size "$cursor_size" 2>/dev/null || true
  fi
  dconf write /org/gnome/desktop/interface/cursor-size "$cursor_size" 2>/dev/null || true

  for conf in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    if [[ -f "$conf" ]]; then
      if grep -q "gtk-cursor-theme-size" "$conf"; then
        sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$cursor_size/g" "$conf"
      else
        echo "gtk-cursor-theme-size=$cursor_size" >> "$conf"
      fi
    fi
  done

  if [[ -f "$HOME/.Xresources" ]]; then
    if grep -q "Xcursor.size" "$HOME/.Xresources"; then
      sed -i "s/Xcursor.size:.*/Xcursor.size: $cursor_size/g" "$HOME/.Xresources"
    else
      echo "Xcursor.size: $cursor_size" >> "$HOME/.Xresources"
    fi
    command -v xrdb >/dev/null 2>&1 && xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
  fi

  # 2. Apply MacOS Dock Settings
  local dock_schema_dir=""
  for d in \
    "$HOME/.local/share/gnome-shell/extensions/macos-dock@vinnytherobot.github.io/schemas" \
    /usr/share/gnome-shell/extensions/macos-dock@vinnytherobot.github.io/schemas
  do
    [[ -d "$d" ]] && dock_schema_dir="$d" && break
  done

  if [[ -n "$dock_schema_dir" ]]; then
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock icon-size "$dock_icon" || true
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock magnification-falloff "$falloff" || true
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock dock-border-radius "$border" || true
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock magnification-scale "$mag_scale" || true
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock animation-duration 160 || true
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock show-threshold "$show_thr" 2>/dev/null || true
  else
    dconf write /org/gnome/shell/extensions/macosdock/icon-size "$dock_icon" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/magnification-falloff "$falloff" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/dock-border-radius "$border" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/magnification-scale "$mag_scale" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/animation-duration 160 2>/dev/null || true
  fi

  # 3. Apply Just Perfection Settings
  local jp_schema_dir=""
  for d in \
    "$HOME/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas" \
    /usr/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas
  do
    [[ -d "$d" ]] && jp_schema_dir="$d" && break
  done

  if [[ -n "$jp_schema_dir" ]]; then
    gsettings --schemadir "$jp_schema_dir" set org.gnome.shell.extensions.just-perfection dash-icon-size "$dash_icon" || true
    gsettings --schemadir "$jp_schema_dir" set org.gnome.shell.extensions.just-perfection panel-icon-size "$panel_icon" || true
    gsettings --schemadir "$jp_schema_dir" set org.gnome.shell.extensions.just-perfection panel-button-padding-size "$pad_btn" || true
    gsettings --schemadir "$jp_schema_dir" set org.gnome.shell.extensions.just-perfection panel-indicator-padding-size "$pad_ind" || true
  fi

  # 4. Blur my Shell Corner Radius (matches dock radius)
  dconf write /org/gnome/shell/extensions/blur-my-shell/panel/corner-radius "$corner" 2>/dev/null || true

  # 5. Magic Lamp Snappiness & Mesh Resolution
  dconf write /org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect/duration 300.0 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect/x-tiles 30.0 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect/y-tiles 30.0 2>/dev/null || true

  # 6. Vitals Top Bar Width
  local vitals_dir=""
  for d in \
    "$HOME/.local/share/gnome-shell/extensions/Vitals@CoreCoding.com/schemas" \
    /usr/share/gnome-shell/extensions/Vitals@CoreCoding.com/schemas
  do
    [[ -d "$d" ]] && vitals_dir="$d" && break
  done
  if [[ -n "$vitals_dir" ]]; then
    gsettings --schemadir "$vitals_dir" set org.gnome.shell.extensions.vitals fixed-widths false || true
  else
    dconf write /org/gnome/shell/extensions/vitals/fixed-widths false 2>/dev/null || true
  fi

  log "Scale adaptation successfully completed"
}

main "$@"
