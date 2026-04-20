# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles repo for zsh, vim/neovim, tmux, and related config. Forked from nicknisi/dotfiles. Supports both macOS and Linux (primary target for this checkout is Linux — see `uname` branches throughout).

## Installation and linking model

`install.sh` is the entry point. It:

1. Runs `git submodule update --init --recursive` (pulls `.config/base16-shell`).
2. Sources `install/link.sh`, which is the core symlink mechanism: every file/dir ending in `.symlink` anywhere up to 3 levels deep gets symlinked to `~/.<basename>` (e.g. `vimrc.symlink` → `~/.vimrc`, `vim.symlink` → `~/.vim`). Everything under `.config/` is symlinked into `~/.config/`. Existing targets are skipped, not overwritten.
3. On macOS: sources `install/brew.sh`, `install/osx.sh`, `install/nvm.sh`.
4. On Linux: installs apt packages (zsh, tmux, ack, vim, build-essential, resilio-sync, etc.), installs nvm, creates `~/.vim-tmp`.
5. Always: creates `~/bin`, `chsh` to zsh, appends `source $DOTFILES/zsh/zshrc.bootstrap` to `~/.zshrc`, runs `nvm install stable`.

`install/software.sh` is a separate, manually-run Linux script for Keybase, VS Code, asdf, Crystal — not called from `install.sh`.

When adding a new dotfile, name it `<name>.symlink` (or put a directory in `.config/`) and `install/link.sh` handles it automatically — no script edits needed.

## ZSH configuration architecture

The `~/.zshrc` created by installation is a one-liner that sources `$DOTFILES/zsh/zshrc.bootstrap`. That file:

- Exports `DOTFILES`, `ZSH=$DOTFILES/zsh`, `CODE_DIR=~/git` (if present — drives the `c` completion).
- Globs `$ZSH/**/*.zsh` and sources every match. **Order is not controlled** — any file matching `*.zsh` under `zsh/` is loaded, so new config should be drop-in and order-independent.
- Sources `~/.localrc` if present (intended for machine-local secrets/API keys, not checked into the repo).
- Also globs and sources `$ZSH/**/*completion.sh`.
- Adds `$DOTFILES/bin` and any `~/bin/*/bin` directories to PATH.
- Branches on `uname` for Linux-vs-macOS-specific setup (asdf path, `open` alias, `xclip` selection, caps-lock remap).
- Sets `THEME=base16-atelier-lakeside` and sources the matching base16-shell script from the submodule.

When adding new zsh config: drop a `*.zsh` file into `zsh/` (it will be auto-sourced) rather than editing `zshrc.bootstrap`. Reserve `zshrc.bootstrap` for PATH/env bootstrapping that must run in a specific order.

## Vim / Neovim

`vimrc.symlink` → `~/.vimrc` and `vim.symlink` → `~/.vim`. Plugins are managed with vim-plug; first-time setup is `nvim +PlugInstall` (or `vim +PlugInstall`). The README describes a shared config for both, but note `zsh/aliases.zsh` aliases `vim=nvim` while `zshrc.bootstrap` has `alias vim=vi` — the aliases file wins because it's sourced after bootstrap via the glob.

## Platform-conditional code

Most scripts branch on `uname` or `$(uname -s)`. When editing cross-platform code, preserve both branches — this repo is used on both Pop!_OS/Linux and macOS. Linux-specific concerns in `install.sh` include resilio-sync repo setup, apt package list, and `setxkbmap` for caps-lock remap.

## Submodules

`.config/base16-shell` is a git submodule. After cloning, `git submodule update --init --recursive` is required (run automatically by `install.sh`). Colorscheme changes happen by changing `THEME` in `zshrc.bootstrap` to match a script under `.config/base16-shell/scripts/`.

## Scripts in `bin/`

`bin/` is prepended to PATH. Notable: `tm`/`tms` (tmux session helpers), `gitme`, `vh` (vhost helper), `battery_indicator.sh`. These are user-facing commands, not build tooling.

## No build / test / lint

There are no package.json, Makefile, or test suite. "Testing" a change means sourcing the affected zsh file (or `reload!`) and verifying behavior in a shell, or running `./install.sh` on a throwaway environment. Don't invent CI or add test harnesses unless explicitly requested.
