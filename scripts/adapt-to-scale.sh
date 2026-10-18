#!/usr/bin/env bash
# Adapt dock / panel pixel sizes to this machine's display.
# Never changes display scale or text-scaling-factor — only our UI sizes.
set -euo pipefail

log()  { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

# Tuned on ~1080 logical-px tall (e.g. 4K @ 200%, or 1080p @ 100%)
REF_LOGICAL_H=1080
REF_TEXT_SCALE=1.25

read_geometry() {
  python3 - <<'PY'
import sys

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
except Exception as e:
    print(f"warn:{e}", file=sys.stderr)

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
  log "Adapting UI sizes to this machine's scale (leaving your scale settings alone)"

  local geo ui_scale text_scale logical_w logical_h layout_scale mode_scale renderer factor
  geo="$(read_geometry)"
  ui_scale="$(echo "$geo" | awk '{print $1}')"
  text_scale="$(echo "$geo" | awk '{print $2}')"
  logical_w="$(echo "$geo" | awk '{print $3}')"
  logical_h="$(echo "$geo" | awk '{print $4}')"
  layout_scale="$(echo "$geo" | awk '{print $5}')"
  mode_scale="$(echo "$geo" | awk '{print $6}')"
  renderer="$(echo "$geo" | awk '{print $7}')"

  factor="$(python3 -c "
logical_h=float('$logical_h')
text=float('$text_scale')
ref_h=float('$REF_LOGICAL_H')
ref_t=float('$REF_TEXT_SCALE')
f = logical_h / ref_h
# mild text-scale nudge so huge fonts get slightly larger chrome
f *= max(0.85, min(1.15, text / ref_t))
print(max(0.65, min(1.45, f)))
")"

  local dock_icon falloff border show_thr dash_icon panel_icon pad_btn pad_ind corner mag_scale
  dock_icon="$(clamp "$(round_mul 56 "$factor")" 36 72)"
  falloff="$(clamp "$(round_mul 130 "$factor")" 80 180)"
  border="$(clamp "$(round_mul 22 "$factor")" 12 28)"
  show_thr="$(clamp "$(round_mul 25 "$factor")" 16 40)"
  dash_icon="$(clamp "$(round_mul 48 "$factor")" 32 64)"
  panel_icon="$(clamp "$(round_mul 22 "$factor")" 16 28)"
  pad_btn="$(clamp "$(round_mul 5 "$factor")" 2 10)"
  pad_ind="$(clamp "$(round_mul 6 "$factor")" 2 12)"
  corner="$(clamp "$(round_mul 24 "$factor")" 12 32)"

  mag_scale="$(python3 -c "
f=float('$factor')
print(1.45 if f < 0.85 else (1.55 if f < 1.0 else 1.65))
")"

  echo "  ui_scale=$ui_scale (layout=$layout_scale mode=$mode_scale renderer=$renderer)"
  echo "  text-scale=$text_scale  logical=${logical_w}x${logical_h}  factor=$factor"
  echo "  dock icon=$dock_icon  falloff=$falloff  mag=$mag_scale  panel-icon=$panel_icon"

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
    gsettings --schemadir "$dock_schema_dir" set org.gnome.shell.extensions.macosdock show-threshold "$show_thr" 2>/dev/null || true
  else
    dconf write /org/gnome/shell/extensions/macosdock/icon-size "$dock_icon" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/magnification-falloff "$falloff" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/dock-border-radius "$border" 2>/dev/null || true
    dconf write /org/gnome/shell/extensions/macosdock/magnification-scale "$mag_scale" 2>/dev/null || true
  fi

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

  dconf write /org/gnome/shell/extensions/blur-my-shell/panel/corner-radius "$corner" 2>/dev/null || true

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

  log "Scale adaptation done"
}

main "$@"
