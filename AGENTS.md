# Agent instructions — bemnet-gnome

Apply this Ubuntu GNOME desktop customization on the user’s machine.

**Agent-first:** when they ask to install, set up, or apply this look — run the installer. Do not only explain unless they ask for explanation only.

## Target

- Ubuntu **24.04** · GNOME Shell **46**
- Gestures need **Ubuntu on Xorg**. If they are on Wayland, still install; warn that gestures need Xorg after logout.

## Rules

1. Use `./install.sh` and `./scripts/install-extensions.sh` — do not invent another theme stack.
2. Only change look-and-feel from this repo. Do not touch unrelated dotfiles, credentials, or other apps.
3. Scripts may need `sudo`. If elevation fails, give the exact command to run in a terminal.
4. Do not commit or push unless asked.
5. After success, keep the wrap-up short: log out → **Ubuntu on Xorg** → log in.

## Steps

From the repo root:

### 1. Preflight

```bash
echo "SESSION=$XDG_SESSION_TYPE DESKTOP=$XDG_CURRENT_DESKTOP"
gnome-shell --version 2>/dev/null || true
lsb_release -ds 2>/dev/null || true
```

Stop or adapt carefully if this is not Ubuntu GNOME.

### 2. Install

```bash
chmod +x install.sh scripts/install-extensions.sh
./install.sh
```

Needs network and sudo. Fix failures and retry.

### 3. If extensions failed

```bash
./scripts/install-extensions.sh
./install.sh --settings-only
```

Use `extensions.txt` / Extension Manager only for what still fails.

### 4. Tell the user

1. Log out.  
2. Login screen → gear → **Ubuntu on Xorg** (for gestures).  
3. Log back in.

## Themes only

```bash
./install.sh --themes-only
```

## Re-run

`./install.sh --settings-only` and `./scripts/install-extensions.sh` are safe to repeat.

## Out of scope

Editor/terminal themes, wallpapers, monitors, or unrelated system config.

## Included top bar extras

- **Vitals** (`Vitals@CoreCoding.com`) — live CPU/RAM/GPU/network/temps  
- **EthCal** (`eth-cal@dagimg-dot`) — Ethiopian calendar (GitHub zip, not e.g.o)  
- **Pomodoro** (`pomodoro@arun.codito.in`) — apt `gnome-shell-pomodoro`  
- Workspace shortcuts: `Ctrl+Alt+A/D` (see `dconf/03-keybindings.ini`)

## Included apps

- **CopyQ** — clipboard manager (`apt install copyq`); config in `configs/copyq/`, autostart in `configs/autostart/`. Do **not** ship clipboard history `.dat` files.
