# Dotfiles

Personal configuration for zsh, vim, tmux, and related tools. Forked from [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles) and streamlined for minimal, opt-in setup. Supports macOS and Linux (primary target: Pop!_OS).

## Contents

- [Initial Setup and Installation](#initial-setup-and-installation)
- [ZSH](#zsh)
- [Vim](#vim)
- [Tmux](#tmux)
- [Fonts](#fonts)
- [Optional tools (extras/)](#optional-tools-extras)
- [Adding new config](#adding-new-config)

## Initial Setup and Installation

### Prerequisites

**macOS** — install the Xcode CLI tools (provides git):

```bash
xcode-select --install
```

**Linux (Pop!_OS / Debian / Ubuntu)** — install git and curl:

```bash
sudo apt install -y git curl
```

If you skip this step, `install.sh` will try to install them itself on Linux, or prompt you to run `xcode-select --install` on macOS.

### Install

Clone the repo (anywhere — symlinks reference it from `$HOME`) and run the installer:

```bash
git clone https://github.com/da1nerd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### What `install.sh` does

1. Populates the `base16-shell` submodule (or clones it manually if you downloaded the repo as a zip).
2. Runs `install/link.sh`, which symlinks every `*.symlink` file to `~/.<name>` (e.g., `vimrc.symlink` → `~/.vimrc`) and everything under `.config/` into `~/.config/`.
3. **macOS**: installs Homebrew and runs [`brew.sh`](install/brew.sh) + [`osx.sh`](install/osx.sh). Read `osx.sh` before running — it sets a number of system preferences; comment out anything you don't want.
4. **Linux**: installs apt packages (zsh, tmux, vim, build-essential, resilio-sync, etc.), installs [starship](https://starship.rs) via the official curl script, and downloads [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) to `~/.local/share/fonts/`.
5. **Both platforms**: clones nvm to `~/.nvm` and [antidote](https://getantidote.github.io) to `~/.antidote` (both idempotent), changes the login shell to zsh, appends the bootstrap line to `~/.zshrc`, and runs `nvm install stable`.

### Next steps (printed at the end)

1. **Log out and back in** for the zsh shell change to take effect.
2. **Install vim plugins**: `vim +PlugInstall`.
3. **Set your terminal emulator font** to *"JetBrainsMono Nerd Font Mono"* so starship's git-branch and status glyphs render.
4. **Linux only**: configure caps-lock-as-Ctrl via your system's keyboard settings (Pop!_OS Settings → Keyboard, or install `gnome-tweaks`). The dotfiles no longer do this per-shell.

## ZSH

`~/.zshrc` is a one-liner that sources [`zsh/zshrc.bootstrap`](zsh/zshrc.bootstrap). The bootstrap:

- Exports `DOTFILES`, `EDITOR=vim`, `THEME`, `BACKGROUND`, and `CODE_DIR=~/git` (if that directory exists).
- Sets PATH via a zsh `path` array (`typeset -U path` auto-deduplicates).
- Glob-sources every `*.zsh` file under `zsh/` — modules are order-independent.
- Sources `~/.localrc` if present (for machine-local secrets / overrides not in git).
- Initializes completion (`compinit`).
- Loads plugins via antidote from [`zsh/.zsh_plugins.txt`](zsh/.zsh_plugins.txt).
- Initializes [starship](https://starship.rs) as the prompt.
- Sources tool integrations with existence guards: asdf, nvm, Android SDK, Java.

### Plugins

Three zsh quality-of-life plugins via antidote:

- [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) — inline gray suggestions from history (press → to accept)
- [`zsh-history-substring-search`](https://github.com/zsh-users/zsh-history-substring-search) — substring history search with ↑/↓
- [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting) — red-for-invalid, green-for-valid command coloring

### Prompt

[starship](https://starship.rs) provides the prompt. Out of the box it shows the current directory, git branch + dirty indicator + ahead/behind arrows, language versions when relevant, exit code of the previous command, and more. Customize via `~/.config/starship.toml` (not committed here).

## Vim

[`vimrc.symlink`](vimrc.symlink) is a slim (~50 line) config used for git commit messages and quick edits — not full IDE work. Two plugins managed by [vim-plug](https://github.com/junegunn/vim-plug):

- `chriskempson/base16-vim` — colorscheme matching the shell's `$THEME`
- `tpope/vim-fugitive` — git inside vim (`:Git`, `:Git blame`, etc.)

Run `vim +PlugInstall` once to download the plugins. **Neovim is not installed or configured by this repo.**

## Tmux

[`tmux/tmux.conf.symlink`](tmux/tmux.conf.symlink) is a minimal (~20 line) config:

- `C-a` prefix (replaces the default `C-b`)
- Mouse on (pane resize, window switch, selection)
- Vi-style copy-mode (matches vim muscle memory)
- 1-indexed windows and panes, auto-renumber on close
- 10,000-line scrollback
- 256-color terminal, short escape-time for vim responsiveness

No plugin manager, no custom theme — defaults are fine.

## Fonts

`install.sh` downloads **JetBrainsMono Nerd Font** automatically: to `~/.local/share/fonts/` on Linux (via curl + unzip), or via `brew install --cask font-jetbrains-mono-nerd-font` on macOS. Point your terminal emulator at *"JetBrainsMono Nerd Font Mono"* for starship's glyph icons to render — this is a one-time manual step in the terminal's preferences.

## Optional tools (`extras/`)

Opt-in installer scripts for tools you might want but don't need by default. Each is self-contained, idempotent, and handles its own platform branching:

```bash
./extras/rust
```

See [`extras/README.md`](extras/README.md) for the full list.

Currently included: `asdf`, `claude` (Claude Code + superpowers plugin), `crystal`, `docker`, `fly` (fly.io CLI), `kvm`, `python`, `ruby`, `rust`, `vscode`.

## Adding new config

- **New dotfile**: name the file `<name>.symlink` (or put a directory under `.config/`). [`install/link.sh`](install/link.sh) handles the symlinking automatically — no script edits needed.
- **New zsh module**: drop a `*.zsh` file under `zsh/`. It'll be auto-sourced. Order isn't controlled, so the file should be drop-in.
- **New zsh plugin**: add a line to `zsh/.zsh_plugins.txt` (keep `zsh-syntax-highlighting` last — it wraps ZLE widgets).
- **New vim plugin**: add a `Plug '<repo>'` line between the `plug#begin/plug#end` markers in `vimrc.symlink`, then `:PlugInstall`.
- **New optional tool**: add an executable script under `extras/` and a row in `extras/README.md`.
