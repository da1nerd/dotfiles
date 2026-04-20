# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles repo for zsh, vim, tmux, and related config. Forked from nicknisi/dotfiles. Supports both macOS and Linux (primary target for this checkout is Linux — see `uname` branches throughout).

## Installation and linking model

`install.sh` is the entry point. It:

1. Runs `git submodule update --init --recursive` (pulls `.config/base16-shell`).
2. Sources `install/link.sh`, which is the core symlink mechanism: every file/dir ending in `.symlink` anywhere up to 3 levels deep gets symlinked to `~/.<basename>` (e.g. `vimrc.symlink` → `~/.vimrc`, `vim.symlink` → `~/.vim`). Everything under `.config/` is symlinked into `~/.config/`. Existing targets are skipped, not overwritten.
3. On macOS: sources `install/brew.sh`, `install/osx.sh`.
4. On Linux: installs apt packages (zsh, tmux, vim, build-essential, resilio-sync, etc.), creates `~/.vim-tmp`, installs starship via the official curl script.
5. Always (both platforms): creates `~/bin`, clones nvm, clones antidote, guarded by existence checks (idempotent); `chsh` to zsh (if not already), appends `source $DOTFILES/zsh/zshrc.bootstrap` to `~/.zshrc` (if not already there), runs `nvm install stable`.

Optional tools live in `extras/` (asdf, crystal, docker, fly, kvm, python, ruby, rust, vscode). Each is a self-contained, idempotent install script. Run `./extras/<tool>` to install one; `extras/README.md` lists what's available. Not called from `install.sh`.

When adding a new dotfile, name it `<name>.symlink` (or put a directory in `.config/`) and `install/link.sh` handles it automatically — no script edits needed.

## ZSH configuration architecture

The `~/.zshrc` created by installation is a one-liner that sources `$DOTFILES/zsh/zshrc.bootstrap`. That file:

- Exports `DOTFILES`, `ZSH=$DOTFILES/zsh`, `EDITOR=vim`, `THEME`, `BACKGROUND`, `CODE_DIR=~/git` (if present).
- Sets PATH in one consolidated block using zsh's `path` array (`typeset -U path` auto-dedupes). Globs like `~/bin/*/bin(N)` use the `(N)` null-glob qualifier to be safe when nothing matches.
- Globs `$ZSH/**/*.zsh(N)` and sources every match. **Order is not controlled** — `*.zsh` files should be drop-in and order-independent.
- Sources `~/.localrc` if present (intended for machine-local secrets/API keys, not checked into the repo).
- Initializes tab completion via `compinit`.
- Loads plugins via antidote from `$ZSH/.zsh_plugins.txt` (currently: zsh-autosuggestions, zsh-history-substring-search, zsh-syntax-highlighting).
- Sources tool integrations guarded by existence checks: asdf, nvm, Android SDK, Java.
- Branches on `uname` for Linux-only aliases (`open=nautilus`, `xclip -selection c`).
- Sources the base16 colorscheme (`$THEME`) from the `base16-shell` submodule.
- Initializes starship for the prompt (`eval "$(starship init zsh)"` guarded by `command -v starship`).

When adding new zsh config: drop a `*.zsh` file into `zsh/` (it will be auto-sourced) rather than editing `zshrc.bootstrap`. Reserve `zshrc.bootstrap` for PATH/env bootstrapping that must run in a specific order.

For new plugins: add a line to `zsh/.zsh_plugins.txt`. Keep `zsh-syntax-highlighting` last since it wraps ZLE widgets and needs to see final widget state.

## Vim

`vimrc.symlink` → `~/.vimrc` and `vim.symlink` → `~/.vim`. Plugins are managed with vim-plug; first-time setup is `vim +PlugInstall`. Two plugins: `base16-vim` (colorscheme, matches `$THEME` from the shell) and `vim-fugitive` (git). The config is slim (~50 lines) — vim is used for git commits and quick edits, not full IDE work. Neovim is NOT installed by this repo.

## Platform-conditional code

Most scripts branch on `uname` or `$(uname -s)`. When editing cross-platform code, preserve both branches — this repo is used on both Pop!_OS/Linux and macOS. Linux-specific concerns in `install.sh` include resilio-sync repo setup and the apt package list. Caps-lock-as-Ctrl is NOT managed by this repo — configure via Pop!_OS keyboard settings / `gnome-tweaks` as a one-time system action.

## Submodules

`.config/base16-shell` is a git submodule. After cloning, `git submodule update --init --recursive` is required (run automatically by `install.sh`). Colorscheme changes happen by changing `THEME` in `zshrc.bootstrap` to match a script under `.config/base16-shell/scripts/`.

## Scripts in `bin/`

`bin/` is prepended to PATH. Notable: `gitme` (clone a github repo into `~/git/`). These are user-facing commands, not build tooling.

## No build / test / lint

There are no package.json, Makefile, or test suite. "Testing" a change means sourcing the affected zsh file (or `reload!`) and verifying behavior in a shell, or running `./install.sh` on a throwaway environment. Don't invent CI or add test harnesses unless explicitly requested.
