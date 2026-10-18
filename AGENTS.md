# Agent instructions — bemnet-gnome

Apply this Ubuntu GNOME desktop customization on the user’s machine.

**Agent-first:** if they ask to install, set up, apply, rice, or “make it look like this” — **run the installer immediately**. Do not only explain unless they ask for explanation only.

## Target

- Ubuntu **24.04** · GNOME Shell **46**
- Gestures need **Ubuntu on Xorg**. If they are on Wayland, still install; warn that gestures need Xorg after logout.

## Rules

1. Use `./install.sh` and `./scripts/install-extensions.sh` — do not invent another theme stack.
2. Only change look-and-feel from this repo. Do not touch unrelated dotfiles, credentials, or other apps.
3. Scripts may need `sudo`. If elevation fails, give the exact command to run in a terminal, then continue after they run it.
4. Do **not** change the user’s display scale or `text-scaling-factor`. Sizing is handled by `scripts/adapt-to-scale.sh`.
5. Do not commit or push unless asked.
6. After success, keep the wrap-up short: log out → **Ubuntu on Xorg** → log in.

## Steps

From the repo root:

### 1. Preflight

```bash
echo "SESSION=$XDG_SESSION_TYPE DESKTOP=$XDG_CURRENT_DESKTOP"
gnome-shell --version 2>/dev/null || true
lsb_release -ds 2>/dev/null || true
```

Stop or adapt carefully if this is not Ubuntu GNOME.

### 2. Install (required)

```bash
chmod +x install.sh scripts/install-extensions.sh scripts/adapt-to-scale.sh
./install.sh
```

Needs network and sudo. Fix failures and retry.

This installs themes, icons, extensions (including Vitals + EthCal), CopyQ, Pomodoro, dconf settings, **and** runs scale adaptation automatically.

### 3. If extensions failed

```bash
./scripts/install-extensions.sh
./install.sh --settings-only
```

Use `extensions.txt` / Extension Manager only for what still fails.

### 4. If UI looks cramped / overlapping on their monitor

```bash
./scripts/adapt-to-scale.sh
```

Safe to re-run. Does not change their scale — only dock/panel/vitals pixel sizes.

### 5. Tell the user

1. Log out.  
2. Login screen → gear → **Ubuntu on Xorg** (for gestures).  
3. Log back in.

Shortcuts to mention if useful: **Ctrl+Alt+A/D** workspaces, **Ctrl+Shift+C** CopyQ, **Ctrl+Alt+P** Pomodoro.

## Themes only

```bash
./install.sh --themes-only
```

## Re-run

`./install.sh --settings-only`, `./scripts/install-extensions.sh`, and `./scripts/adapt-to-scale.sh` are safe to repeat.

## Out of scope

Editor/terminal themes, wallpapers, monitors, or unrelated system config.

## Included stack (expect these after install)

- **Orchis-Grey-Dark** + **WhiteSur-Panel** icons  
- **Just Perfection**, **Blur my Shell**, **Burn My Windows**, **Magic Lamp**  
- **MacOS Dock** (auto-hide)  
- **Vitals** — CPU/RAM/GPU/network/temps  
- **EthCal** — Ethiopian calendar (GitHub zip, not e.g.o)  
- **Pomodoro** — apt `gnome-shell-pomodoro`  
- **CopyQ** — clipboard history + autostart (never copy `.dat` history files)  
- **X11 Gestures + Touchégg**, **Pop Shell** (tiling off by default)  
- Workspace shortcuts: `Ctrl+Alt+A/D` (`dconf/03-keybindings.ini`)  
- **Scale-adaptive** dock/panel sizing via `scripts/adapt-to-scale.sh`
