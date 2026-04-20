# Tmux slim-down — design

Phase 2b of the multi-phase dotfiles cleanup. Phases 1 (deletions), 2a (vim),
and 3 (install-script hardening) are complete. Phase 2c (zsh) is pending.

## Context

Tmux surface area in the dotfiles:

- `tmux/tmux.conf.symlink` — 115 lines, uses tmux 2.3-era syntax. Contains
  `bind -t vi-copy` (removed in tmux 2.4) and sources `theme.sh` which uses
  `status-attr`, `window-status-fg/bg`, `pane-border-fg`, `message-fg/bg`
  (all removed in tmux 2.9).
- `tmux/theme.sh` — 59 lines, all commands are no-ops or errors on tmux 3.2.
- `tmux/human.sh` — 54 lines, alternate theme not even sourced anywhere.
- `tmux/dev.tmux.conf.symlink` — 8 lines, predefined "dev" session layout.
- `bin/tm` — interactive session picker menu.
- `bin/tms` — tmux session save/restore helper.
- `bin/battery_indicator.sh` — only referenced by `theme.sh` / `human.sh`;
  also broken on modern kernels (reads `/proc/acpi/battery/BAT1/` which was
  replaced by `/sys/class/power_supply/BAT0/` years ago).
- `zsh/tmux.zsh` — 4 aliases (`ta`, `tls`, `tat`, `tns`).

User's actual usage: **barely used — installed by habit, rarely open it.**
Current system tmux is 3.2a (2021).

## Decisions

1. **Keep tmux installed** via apt. Sometimes a slim config is better than no
   tmux at all.
2. **Replace the config with a minimal tmux.conf (~20 lines).** Raw tmux
   defaults are bad enough (C-b prefix, no mouse, 0-indexed windows) that a
   handful of lines meaningfully improve the rare tmux session. Matches the
   vim-slim-down precedent.
3. **Delete the theme files entirely.** They're broken on tmux 3.2 and serve
   a customization level ("barely used" doesn't need).
4. **Delete the session-helper scripts** (`bin/tm`, `bin/tms`). Tied to
   heavy tmux use; not warranted.
5. **Delete `battery_indicator.sh`.** Only consumed by the theme files, and
   broken on modern kernels anyway.
6. **Keep `zsh/tmux.zsh` aliases.** 4 lines, functional, zero maintenance.

## Changes

### `tmux/tmux.conf.symlink` — rewrite

Full replacement contents:

```tmux
# Minimal tmux config — defaults are mostly fine, these are worth setting.

# Ctrl-a prefix (ergonomics: C-b is awkward)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Proper 256-color support
set -g default-terminal "screen-256color"

# Mouse on — pane resize, window switch, selection
set -g mouse on

# 1-indexed windows and panes (keyboard reach)
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# vi copy-mode (matches vim muscle memory)
setw -g mode-keys vi

# Sensible scrollback
set -g history-limit 10000

# Shorter escape for vim responsiveness
set -sg escape-time 10
```

### `tmux/theme.sh` — delete

Broken syntax, barely-used tool. Remove entirely.

### `tmux/human.sh` — delete

Not sourced by anything, dead file.

### `tmux/dev.tmux.conf.symlink` — delete

Predefined dev-session layout. Barely-used-tier feature.

### `bin/tm` — delete

Interactive session picker; not warranted for the usage pattern.

### `bin/tms` — delete

Session save/restore; not warranted.

### `bin/battery_indicator.sh` — delete

Only referenced by deleted theme files. Also broken on modern kernels (reads
`/proc/acpi/battery/BAT1/` — replaced by `/sys/class/power_supply/BAT0/` in
kernels from ~2014 onward).

### `CLAUDE.md` — update

Drop the reference on line 51 to `tm`/`tms`/`battery_indicator.sh`.

### Unchanged

- `zsh/tmux.zsh` — keep the 4 aliases (`ta`, `tls`, `tat`, `tns`).
- `install.sh` — `tmux` stays in the apt install list.

## Validation

1. `tmux kill-server 2>/dev/null; tmux -f ~/.dotfiles/tmux/tmux.conf.symlink new -d -s smoke 2>&1`
   — server starts with the new config; no errors on stderr.
2. `tmux show-options -g prefix` — output contains `C-a`.
3. `tmux show-options -g base-index` — output contains `1`.
4. `tmux show-options -g mouse` — output contains `on`.
5. `tmux show-options -g mode-keys -w` — output contains `vi`.

Clean up after verification: `tmux kill-session -t smoke`.

## Out of scope

- TPM (Tmux Plugin Manager) adoption — YAGNI for barely-used tmux.
- Status-bar theming / colors — not worth rebuilding the broken theme.
- Key bindings beyond `prefix` remap — defaults are fine.
- Session persistence (resurrect/continuum) — covered by deleting `bin/tms`.
- Changes to `zsh/tmux.zsh` aliases — keeping them as-is.
- Removing `tmux` from the apt install list — keeping it installed.
