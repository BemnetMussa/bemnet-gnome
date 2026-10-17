#!/usr/bin/env bash
# customizelinux — apply Bemnet's Ubuntu GNOME look (themes, blur, gestures, dock)
# Tested target: Ubuntu 24.04 LTS · GNOME Shell 46 · X11 session (for trackpad gestures)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/customizelinux"
mkdir -p "$CACHE"

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || { warn "Missing dependency: $1"; return 1; }; }

check_env() {
  log "Checking environment"
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "OS: ${PRETTY_NAME:-unknown}"
  fi
  if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version
  else
    warn "gnome-shell not found — this rice is for GNOME on Ubuntu."
  fi
  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    warn "You are on Wayland. X11 Gestures + Touchégg need an X11 session."
    warn "Log in with 'Ubuntu on Xorg' for the trackpad gestures to match."
  fi
}

install_apt_deps() {
  log "Installing apt packages (needs sudo)"
  sudo apt-get update -qq
  sudo apt-get install -y \
    git curl unzip dconf-cli gnome-tweaks \
    gnome-shell-extensions \
    gnome-shell-extension-prefs \
    chrome-gnome-shell 2>/dev/null || true

  # Pop Shell (tiling) — ignore if unavailable
  sudo apt-get install -y gnome-shell-extension-pop-shell 2>/dev/null || \
    warn "pop-shell package not found; install the extension manually later."

  # Touchégg (gesture engine for X11)
  if ! command -v touchegg >/dev/null 2>&1; then
    log "Installing Touchégg"
    if ! apt-cache show touchegg >/dev/null 2>&1; then
      curl -fsSL https://raw.githubusercontent.com/JoseExposito/touchegg/master/installation/ubuntu.sh \
        | sudo bash || warn "Touchégg install helper failed — install from https://github.com/JoseExposito/touchegg"
    else
      sudo apt-get install -y touchegg
    fi
  fi
  sudo systemctl enable touchegg.service 2>/dev/null || true
  sudo systemctl start touchegg.service 2>/dev/null || true
}

install_orchis() {
  log "Installing Orchis-Grey-Dark GTK + Shell theme"
  local dir="$CACHE/Orchis-theme"
  if [[ ! -d "$dir/.git" ]]; then
    git clone --depth 1 https://github.com/vinceliuice/Orchis-theme.git "$dir"
  else
    git -C "$dir" pull --ff-only || true
  fi
  # grey + dark, link for libadwaita apps
  (cd "$dir" && ./install.sh -t grey -c dark -l --shell 46)
}

install_whitesur_icons() {
  log "Installing WhiteSur icon theme + Panel overlay"
  local dir="$CACHE/WhiteSur-icon-theme"
  if [[ ! -d "$dir/.git" ]]; then
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$dir"
  else
    git -C "$dir" pull --ff-only || true
  fi
  (cd "$dir" && ./install.sh)

  # Small panel status overlay used by this rice
  mkdir -p "$HOME/.local/share/icons"
  rm -rf "$HOME/.local/share/icons/WhiteSur-Panel"
  cp -a "$ROOT/icons/WhiteSur-Panel" "$HOME/.local/share/icons/"
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/WhiteSur-Panel" 2>/dev/null || true
}

install_extension_configs() {
  log "Installing Burn My Windows profile + Touchégg config"
  mkdir -p "$HOME/.config/burn-my-windows/profiles"
  cp -f "$ROOT/configs/burn-my-windows/profiles/macos-smooth.conf" \
    "$HOME/.config/burn-my-windows/profiles/"

  mkdir -p "$HOME/.config/touchegg"
  cp -f "$ROOT/configs/touchegg/touchegg.conf" "$HOME/.config/touchegg/touchegg.conf"
}

apply_dconf() {
  log "Applying dconf settings"

  dconf load /org/gnome/desktop/interface/ < "$ROOT/dconf/00-interface.ini"
  dconf load /org/gnome/desktop/wm/preferences/ < "$ROOT/dconf/01-wm.ini"
  dconf load /org/gnome/mutter/ < "$ROOT/dconf/02-mutter.ini"

  # Extension keys only apply after the extension is installed
  load_if_dir() {
    local path="$1" file="$2"
    if dconf list "$path" >/dev/null 2>&1 || [[ -d "$HOME/.local/share/gnome-shell/extensions" ]]; then
      # Rewrite BMW profile path to this user
      if [[ "$file" == *burn-my-windows* ]]; then
        local tmp
        tmp="$(mktemp)"
        sed "s|__BMW_PROFILE__|$HOME/.config/burn-my-windows/profiles/macos-smooth.conf|g" \
          "$ROOT/dconf/$file" > "$tmp"
        dconf load "$path" < "$tmp" || warn "Could not load $file (install Burn My Windows first)"
        rm -f "$tmp"
      else
        dconf load "$path" < "$ROOT/dconf/$file" || warn "Could not load $file yet"
      fi
    fi
  }

  load_if_dir /org/gnome/shell/extensions/just-perfection/ 10-just-perfection.ini
  load_if_dir /org/gnome/shell/extensions/blur-my-shell/ 11-blur-my-shell.ini
  load_if_dir /org/gnome/shell/extensions/burn-my-windows/ 12-burn-my-windows.ini
  load_if_dir /org/gnome/shell/extensions/x11gestures/ 13-x11gestures.ini
  load_if_dir /org/gnome/shell/extensions/macosdock/ 14-macosdock.ini
  load_if_dir /org/gnome/shell/extensions/user-theme/ 15-user-theme.ini
  load_if_dir /org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect/ 16-magic-lamp.ini
  load_if_dir /org/gnome/shell/extensions/pop-shell/ 17-pop-shell.ini
}

enable_extensions() {
  log "Enabling look-and-feel extensions (skip if not installed yet)"
  local uuids=(
    user-theme@gnome-shell-extensions.gcampax.github.com
    just-perfection-desktop@just-perfection
    blur-my-shell@aunetx
    burn-my-windows@schneegans.github.com
    x11gestures@joseexposito.github.io
    macos-dock@vinnytherobot.github.io
    compiz-alike-magic-lamp-effect@hermes83.github.com
    pop-shell@system76.com
    ubuntu-appindicators@ubuntu.com
  )
  if ! command -v gnome-extensions >/dev/null 2>&1; then
    warn "gnome-extensions CLI missing — enable them in Extension Manager after install."
    return 0
  fi
  for id in "${uuids[@]}"; do
    if gnome-extensions info "$id" >/dev/null 2>&1; then
      gnome-extensions enable "$id" && echo "  enabled: $id"
    else
      warn "not installed yet: $id"
    fi
  done
}

print_next_steps() {
  cat <<EOF

────────────────────────────────────────────────────────────
Themes, icons, and base configs are in place.

NEXT (agent or human):
  1. ./scripts/install-extensions.sh
  2. ./install.sh --settings-only
  3. Log out → login gear → Ubuntu on Xorg → log in

If an agent is driving setup, it should run steps 1–2 now.

Optional: pick your own wallpaper (none is shipped).
Repo: https://github.com/BemnetMussa/customizelinux
────────────────────────────────────────────────────────────
EOF
}

usage() {
  cat <<EOF
Usage: ./install.sh [OPTIONS]

  (default)         Full install: deps, Orchis, WhiteSur, configs, dconf
  --settings-only   Only copy configs and apply dconf (after extensions)
  --themes-only     Only install Orchis + WhiteSur icons
  -h, --help        Show this help
EOF
}

main() {
  local mode=full
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --settings-only) mode=settings ;;
    --themes-only) mode=themes ;;
    "") mode=full ;;
    *) warn "Unknown option: $1"; usage; exit 1 ;;
  esac

  need git
  need dconf
  check_env

  case "$mode" in
    full)
      install_apt_deps
      install_orchis
      install_whitesur_icons
      install_extension_configs
      # Extensions before final dconf so schemas exist when possible
      if [[ -x "$ROOT/scripts/install-extensions.sh" ]]; then
        log "Installing GNOME Shell extensions"
        "$ROOT/scripts/install-extensions.sh" || warn "Some extensions failed — see extensions.txt"
      fi
      apply_dconf
      enable_extensions
      print_next_steps
      ;;
    themes)
      install_orchis
      install_whitesur_icons
      ;;
    settings)
      install_extension_configs
      apply_dconf
      enable_extensions
      echo "Settings applied."
      ;;
  esac
}

main "$@"
