#!/usr/bin/env bash
# Download + install look-and-feel GNOME Shell extensions for this rice.
# Safe to re-run. Meant for humans and coding agents.
set -euo pipefail

SHELL_MAJOR="$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1 || echo 46)"
EXT_DIR="${HOME}/.local/share/gnome-shell/extensions"
ZIP_DIR="${HOME}/.cache/bemnet-gnome/ext-zips"
mkdir -p "$EXT_DIR" "$ZIP_DIR"

# uuid|extensions.gnome.org pk
EXTENSIONS=(
  "user-theme@gnome-shell-extensions.gcampax.github.com|19"
  "just-perfection-desktop@just-perfection|3843"
  "blur-my-shell@aunetx|3193"
  "burn-my-windows@schneegans.github.com|4679"
  "x11gestures@joseexposito.github.io|4033"
  "macos-dock@vinnytherobot.github.io|7961"
  "compiz-alike-magic-lamp-effect@hermes83.github.com|3740"
)

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need curl
need unzip
need python3

resolve_version() {
  local pk="$1"
  local info
  info="$(curl -fsSL "https://extensions.gnome.org/extension-info/?pk=${pk}&shell_version=${SHELL_MAJOR}")" || return 1
  printf '%s' "$info" | python3 -c "
import sys, json
d = json.loads(sys.stdin.read())
svm = d.get('shell_version_map') or {}
ver = None
for k, v in svm.items():
    if str(k).split('.')[0] == '${SHELL_MAJOR}':
        ver = v.get('version') if isinstance(v, dict) else v
        break
if ver is None and svm:
    first = next(iter(svm.values()))
    ver = first.get('version') if isinstance(first, dict) else first
if ver is None:
    sys.exit(1)
print(int(ver))
"
}

download_zip() {
  local uuid="$1" version="$2" out="$3"
  local slug="${uuid//@/}"
  local urls=(
    "https://extensions.gnome.org/extension-data/${slug}.v${version}.shell-extension.zip"
    "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?version_tag=${version}"
  )
  local url
  for url in "${urls[@]}"; do
    if curl -fsSL -o "$out" "$url" && [[ -s "$out" ]]; then
      return 0
    fi
    rm -f "$out"
  done
  return 1
}

install_one() {
  local uuid="$1" pk="$2"
  local dest="${EXT_DIR}/${uuid}"

  if [[ -d "$dest" ]] || [[ -d "/usr/share/gnome-shell/extensions/${uuid}" ]]; then
    echo "  already present: $uuid"
    return 0
  fi

  echo "  fetching: $uuid (GNOME ${SHELL_MAJOR})"
  local version
  if ! version="$(resolve_version "$pk")"; then
    echo "  !! no compatible version for $uuid"
    return 1
  fi

  local zipfile="${ZIP_DIR}/${uuid//@/_}-v${version}.zip"
  if ! download_zip "$uuid" "$version" "$zipfile"; then
    echo "  !! download failed: $uuid"
    return 1
  fi

  local tmp
  tmp="$(mktemp -d)"
  unzip -qo "$zipfile" -d "$tmp"
  if [[ ! -f "$tmp/metadata.json" ]]; then
    echo "  !! bad zip: $uuid"
    rm -rf "$tmp"
    return 1
  fi

  rm -rf "$dest"
  mkdir -p "$dest"
  cp -a "$tmp"/. "$dest"/
  rm -rf "$tmp"

  if [[ -d "$dest/schemas" ]]; then
    glib-compile-schemas "$dest/schemas" 2>/dev/null || true
  fi

  echo "  installed: $uuid (v${version})"
}

echo "==> GNOME extensions for shell ${SHELL_MAJOR}"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get install -y gnome-shell-extensions gnome-shell-extension-prefs unzip curl 2>/dev/null || true
  sudo apt-get install -y gnome-shell-extension-pop-shell 2>/dev/null || true
fi

failed=0
for entry in "${EXTENSIONS[@]}"; do
  uuid="${entry%%|*}"
  pk="${entry##*|}"
  install_one "$uuid" "$pk" || failed=$((failed + 1))
done

echo
if [[ "$failed" -gt 0 ]]; then
  echo "Installed with ${failed} failure(s). Use Extension Manager for the rest — see extensions.txt"
  exit 1
fi
echo "All extensions installed. Log out/in (or Alt+F2, type r, Enter on X11), then run: ./install.sh --settings-only"
exit 0
