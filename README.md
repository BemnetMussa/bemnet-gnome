# bemnet-gnome

Ubuntu GNOME desktop setup: Orchis Grey Dark theme, WhiteSur icons, blurred top bar, smooth window effects, magnification dock, and trackpad gestures.

| | |
|---|---|
| **OS** | Ubuntu 24.04 LTS |
| **Shell** | GNOME 46 |
| **Session** | Ubuntu on Xorg (required for gestures) |

---

## Install with an agent (recommended)

```bash
git clone https://github.com/BemnetMussa/bemnet-gnome.git
cd bemnet-gnome
cursor .
```

Ask the agent:

> Set up this Ubuntu GNOME customization.

It follows [`AGENTS.md`](AGENTS.md) and runs the installer.

When finished: log out → gear on the login screen → **Ubuntu on Xorg** → log in.

---

## Manual install

```bash
git clone https://github.com/BemnetMussa/bemnet-gnome.git
cd bemnet-gnome
chmod +x install.sh scripts/install-extensions.sh
./install.sh
```

| Command | Purpose |
|---------|---------|
| `./install.sh` | Dependencies, themes, icons, extensions, settings |
| `./install.sh --settings-only` | Re-apply settings after fixing extensions |
| `./install.sh --themes-only` | Themes and icons only |
| `./scripts/install-extensions.sh` | Extensions only |

---

## What you get

- **Orchis-Grey-Dark** — GTK and GNOME Shell theme  
- **WhiteSur** icons with a clearer panel status overlay  
- **Just Perfection** — cleaner top bar  
- **Blur my Shell** — frosted panel and overview  
- **Burn My Windows** — smooth glide open/close  
- **Magic Lamp** — Compiz-style minimize  
- **MacOS Dock** — magnification dock  
- **X11 Gestures + Touchégg** — 3/4-finger trackpad gestures  
- **Pop Shell** — optional tiling (off by default)  

Extension list: [`extensions.txt`](extensions.txt)

## Gestures

| Gesture | Action |
|---------|--------|
| 3 / 4-finger swipe | GNOME Shell gestures |
| 3-finger pinch in | Close window |
| 4-finger pinch out | Show desktop |
| 4-finger pinch in | App grid |
| 2 / 3-finger tap | Right / middle click |

## Layout

```text
bemnet-gnome/
├── AGENTS.md
├── install.sh
├── scripts/install-extensions.sh
├── extensions.txt
├── dconf/
├── configs/
└── icons/WhiteSur-Panel/
```

## Credits

[Orchis](https://github.com/vinceliuice/Orchis-theme) · [WhiteSur icons](https://github.com/vinceliuice/WhiteSur-icon-theme) · [Touchégg](https://github.com/JoseExposito/touchegg) · extension authors in `extensions.txt`

## License

MIT for scripts and configs in this repo. Upstream themes and extensions keep their own licenses.
