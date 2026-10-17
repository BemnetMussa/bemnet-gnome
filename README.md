# customizelinux

Shareable **Ubuntu GNOME** desktop rice — the top bar, icons, window smoothness, and trackpad gestures — without any personal files.

Built for friends who see the setup and ask “how do I make mine look like that?”

| | |
|---|---|
| **Target** | Ubuntu **24.04 LTS** · GNOME Shell **46** |
| **Session** | **X11 / Ubuntu on Xorg** (needed for Touchégg gestures) |
| **Look** | Orchis Grey Dark · WhiteSur icons · blurred panel · smooth window effects · macOS-style dock |

## What’s included

- **Orchis-Grey-Dark** GTK + Shell theme (installed from upstream)
- **WhiteSur** icons + a small **WhiteSur-Panel** status overlay (clearer top-bar icons)
- **Just Perfection** — cleaner top bar (e.g. Activities button off, smoother animations)
- **Blur my Shell** — frosted panel / overview
- **Burn My Windows** — soft “macos-smooth” glide close/open
- **Magic Lamp** — Compiz-style minimize
- **MacOS Dock** — magnification dock
- **X11 Gestures + Touchégg** — 3/4-finger trackpad gestures
- **Pop Shell** — light tiling (optional feel, not forced tile-by-default)

No wallpapers, accounts, SSH keys, browser data, or app secrets are in this repo.

## Quick start

```bash
git clone https://github.com/BemnetMussa/customizelinux.git
cd customizelinux
chmod +x install.sh
./install.sh
```

Then install the extensions listed in [`extensions.txt`](extensions.txt) (Extension Manager or [extensions.gnome.org](https://extensions.gnome.org/)), and run:

```bash
./install.sh --settings-only
```

Log out → log in with **Ubuntu on Xorg** → enjoy.

### Install modes

| Command | Does |
|---------|------|
| `./install.sh` | Deps + themes + icons + configs + dconf |
| `./install.sh --themes-only` | Orchis + WhiteSur only |
| `./install.sh --settings-only` | Re-apply configs after extensions are installed |

## Gestures (X11)

| Fingers | Action |
|---------|--------|
| 3-finger swipe | GNOME Shell gestures (overview / workspace — via X11 Gestures) |
| 4-finger swipe | GNOME Shell gestures |
| 3-finger pinch in | Close window |
| 4-finger pinch out | Show desktop |
| 4-finger pinch in | App grid (`Super+A`) |
| 2 / 3 finger tap | Right / middle click |

Wayland users: switch to **Ubuntu on Xorg** for this gesture stack.

## Layout of this repo

```text
customizelinux/
├── install.sh              # main installer
├── extensions.txt          # extension UUIDs + links
├── dconf/                  # sanitized gsettings dumps
├── configs/
│   ├── burn-my-windows/    # macos-smooth effect profile
│   └── touchegg/           # trackpad gesture config
├── icons/WhiteSur-Panel/   # top-bar status icon overlay
└── screenshots/            # drop your own previews here
```

## Not included (on purpose)

- Personal wallpapers and photo libraries  
- Monitor geometry / HiDPI text scale (set yours in Settings)  
- Work/dev extensions (Vitals, NVIDIA util, calendars, Pomodoro, …)  
- Dotfiles for editors, browsers, terminals, SSH, cloud CLIs  

## Credits

- [Orchis theme](https://github.com/vinceliuice/Orchis-theme) — vinceliuice  
- [WhiteSur icons](https://github.com/vinceliuice/WhiteSur-icon-theme) — vinceliuice  
- Extension authors linked in `extensions.txt`  
- [Touchégg](https://github.com/JoseExposito/touchegg) — JoseExposito  

## License

MIT for the scripts and configs in this repo. Upstream themes/extensions keep their own licenses.
