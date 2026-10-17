# customizelinux

**Agent-first** Ubuntu GNOME rice — top bar, icons, smooth windows, trackpad gestures.

Your friend clones the repo, opens it in **Cursor**, and asks the agent to set it up. No long manual checklist required.

| | |
|---|---|
| **Target** | Ubuntu **24.04 LTS** · GNOME Shell **46** |
| **Session** | **Ubuntu on Xorg** for gestures (Touchégg) |
| **Look** | Orchis Grey Dark · WhiteSur icons · blur · smooth effects · macOS-style dock |

No wallpapers, accounts, SSH keys, or other personal files are included.

---

## For your friend (recommended)

```bash
git clone https://github.com/BemnetMussa/customizelinux.git
cd customizelinux
cursor .    # or: open this folder in Cursor
```

Then tell the agent something like:

> **Set up this Linux customization on my PC.**

The agent reads [`AGENTS.md`](AGENTS.md) and runs the install for you.

When it finishes: **log out → login screen gear → Ubuntu on Xorg → log in.**

---

## Manual install (no agent)

```bash
git clone https://github.com/BemnetMussa/customizelinux.git
cd customizelinux
chmod +x install.sh scripts/install-extensions.sh
./install.sh
./scripts/install-extensions.sh
./install.sh --settings-only
```

Then log out and use **Ubuntu on Xorg**.

| Command | Does |
|---------|------|
| `./install.sh` | Deps + themes + icons + configs |
| `./scripts/install-extensions.sh` | Downloads the look-and-feel GNOME extensions |
| `./install.sh --settings-only` | Re-applies dconf after extensions exist |
| `./install.sh --themes-only` | Orchis + WhiteSur only |

---

## What’s included

- **Orchis-Grey-Dark** GTK + Shell theme  
- **WhiteSur** icons + **WhiteSur-Panel** status overlay  
- **Just Perfection**, **Blur my Shell**, **Burn My Windows**, **Magic Lamp**  
- **MacOS Dock**, **X11 Gestures** + Touchégg, **Pop Shell**  

See [`extensions.txt`](extensions.txt) for UUIDs and links.

## Gestures (X11)

| Fingers | Action |
|---------|--------|
| 3 / 4-finger swipe | GNOME Shell gestures |
| 3-finger pinch in | Close window |
| 4-finger pinch out | Show desktop |
| 4-finger pinch in | App grid |
| 2 / 3 finger tap | Right / middle click |

## Repo layout

```text
customizelinux/
├── AGENTS.md                 # instructions for Cursor / coding agents
├── .cursor/rules/            # always-on agent rule
├── install.sh
├── scripts/install-extensions.sh
├── extensions.txt
├── dconf/                    # sanitized settings
├── configs/                  # burn-my-windows + touchegg
└── icons/WhiteSur-Panel/
```

## Not included

Personal wallpapers, HiDPI scale, work/dev extensions, editor/browser/SSH dotfiles.

## Credits

[Orchis](https://github.com/vinceliuice/Orchis-theme) · [WhiteSur icons](https://github.com/vinceliuice/WhiteSur-icon-theme) · authors in `extensions.txt` · [Touchégg](https://github.com/JoseExposito/touchegg)

## License

MIT for scripts/configs here. Upstream themes and extensions keep their own licenses.
