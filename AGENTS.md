# Agent instructions — customizelinux

You are setting up **Bemnet’s Ubuntu GNOME desktop rice** on the user’s machine.

This repo is **agent-first**: the human clones it, opens it in Cursor (or another coding agent), and asks you to make their Linux look like this. You run the install — they should not have to read a long README.

## Mission

When the user wants this look (any of: “set this up”, “install”, “make my PC look like this”, “apply the rice”, or just opened the repo and asked for help), **execute the full setup**. Do not only explain the steps unless they explicitly ask for an explanation-only answer.

## Target environment

- Ubuntu **24.04** (Noble) · GNOME Shell **46**
- Gestures need **X11** (“Ubuntu on Xorg”). Warn if they are on Wayland; still install everything else.

## Hard rules

1. **Stay inside this repo’s workflow.** Prefer `./install.sh` and `./scripts/install-extensions.sh`. Do not invent a different theme stack.
2. **No personal data.** Never copy wallpapers, SSH keys, browser profiles, `.env`, email, or other home-directory secrets. This rice ships look-and-feel only.
3. **Ask before `sudo` only if the tool cannot elevate** — otherwise run the install scripts; they already call sudo where needed. If sudo fails, tell the user the exact command to re-run in a terminal.
4. **Do not commit or push** unless the user asks.
5. After success, give a **short** “what to do next” (log out → Ubuntu on Xorg). No essay.

## Procedure (run in order)

Work from the repo root (`customizelinux/`).

### 1. Preflight

```bash
echo "SESSION=$XDG_SESSION_TYPE DESKTOP=$XDG_CURRENT_DESKTOP"
gnome-shell --version 2>/dev/null || true
lsb_release -ds 2>/dev/null || true
```

If not Ubuntu/GNOME, warn and stop or adapt carefully. If Wayland, note that trackpad gestures need Xorg later.

### 2. Full install

```bash
chmod +x install.sh scripts/install-extensions.sh
./install.sh
```

This installs deps, Orchis, WhiteSur, Touchégg configs, downloads extensions, applies dconf, and enables what it can. Needs network + sudo. Fix errors and retry — do not skip.

### 3. If extensions partially failed

```bash
./scripts/install-extensions.sh
./install.sh --settings-only
```

Use `extensions.txt` + Extension Manager only for UUIDs that still fail.

### 4. Finish message to the user

Tell them:

1. Log out.
2. On the login screen, choose **Ubuntu on Xorg** (gear icon) if they want trackpad gestures.
3. Log back in — panel blur, dock, window effects, and gestures should match.

Optional: they can pick any wallpaper themselves (none is shipped).

## If the user only wants themes

```bash
./install.sh --themes-only
```

## If something already partially installed

Re-run `./install.sh --settings-only` and `./scripts/install-extensions.sh`. Safe to re-run; scripts are mostly idempotent.

## Out of scope

- Installing Cursor/VS Code themes, terminal themes, neovim, or unrelated dotfiles
- Changing their wallpaper or monitors
- Adding personal/work extensions from the author’s own PC
