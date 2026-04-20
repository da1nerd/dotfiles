# Dotfiles

Personal configuration for zsh, vim, tmux, and related tools. Forked from [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles) and streamlined for minimal, opt-in setup. Supports macOS and Linux (primary target: Pop!_OS).

## Contents

- [Installation](#installation)
- [After install](#after-install)
- [What's included](#whats-included)
- [Optional tools (extras/)](#optional-tools-extras)
- [Adding new config](#adding-new-config)

## Installation

**Prerequisites** — `git` and `curl`.

- macOS: `xcode-select --install`
- Linux (Pop!_OS / Debian / Ubuntu): `sudo apt install -y git curl`

If you skip this step, `install.sh` will try to install them itself.

**Install** — clone anywhere (symlinks reference the repo from `$HOME`) and run:

```bash
git clone https://github.com/da1nerd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## After install

`install.sh` prints the following manual steps at the end:

1. Log out and back in for the zsh shell change to take effect.
2. Install vim plugins: `vim +PlugInstall`.
3. Set your terminal emulator font to **"JetBrainsMono Nerd Font Mono"** so starship's git-branch and status glyphs render.
4. Linux only: configure caps-lock-as-Ctrl via your system's keyboard settings (Pop!_OS Settings → Keyboard, or install `gnome-tweaks`).

## What's included

- **zsh** with [starship](https://starship.rs) prompt and three [antidote](https://getantidote.github.io)-managed plugins: `zsh-autosuggestions` (inline history suggestions), `zsh-history-substring-search` (↑/↓ substring search), `zsh-syntax-highlighting` (red-for-invalid commands).
- **vim** — slim ~50-line config for git commits and quick edits. Two plugins: `base16-vim` (colorscheme) and `vim-fugitive` (git integration).
- **tmux** — minimal ~20-line config: `C-a` prefix, mouse on, vi copy-mode, 1-indexed windows.
- **base16 colorscheme** — shared between terminal, vim, and the rest of the shell via `$THEME`.
- **JetBrainsMono Nerd Font** — installed automatically (terminal emulator needs to be pointed at it manually; see "After install").

## Optional tools (`extras/`)

Opt-in installer scripts for tools you might want but don't need by default. Each script is self-contained and safe to re-run:

```bash
./extras/rust
```

See [`extras/README.md`](extras/README.md) for the full list. Currently: `asdf`, `claude` (Claude Code + superpowers plugin), `crystal`, `docker`, `fly` (fly.io CLI), `kvm`, `python`, `ruby`, `rust`, `vscode`.

## Adding new config

- **New dotfile**: name it `<name>.symlink` (or put a directory under `.config/`) — [`install/link.sh`](install/link.sh) handles it automatically.
- **New zsh module**: drop a `*.zsh` file under `zsh/` — it'll be auto-sourced.
- **New zsh plugin**: add a line to `zsh/.zsh_plugins.txt` (keep `zsh-syntax-highlighting` last).
- **New vim plugin**: add a `Plug '<repo>'` line in `vimrc.symlink`, then `:PlugInstall`.
- **Machine-local overrides**: create `~/.localrc`; it's sourced by the zsh bootstrap and isn't tracked in git.
- **New optional tool**: add an executable script under `extras/` and a row in `extras/README.md`.
