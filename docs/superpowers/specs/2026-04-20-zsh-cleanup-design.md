# Zsh cleanup — design

Phase 2c of the multi-phase dotfiles cleanup. Phases 1 (deletions), 2a (vim),
2b (tmux), and 3 (install-script hardening) are complete. Phase 4 (software
library) is the only remaining phase after this.

## Context

Current zsh surface area:

- `zsh/zshrc.bootstrap` — 145 lines. Mixes env setup, scattered PATH
  additions, platform branches, tool-specific init (asdf, nvm, flutter,
  electronite, composer, mysql, Android SDK, Java, iTerm2, travis, yarn),
  inline aliases, and base16 theme setup. Many tool paths point at
  non-existent directories on this machine.
- `zsh/prompt.zsh` — 70-line hand-rolled git-aware prompt using `vcs_info`,
  showing branch, dirty indicator, `⇡N ⇣N` ahead/behind arrows, and
  suspended-jobs marker.
- `zsh/aliases.zsh`, `zsh/completion.zsh`, `zsh/config.zsh`,
  `zsh/functions.zsh`, `zsh/git.zsh`, `zsh/tmux.zsh` — task-specific
  modules, auto-sourced via the `$ZSH/**/*.zsh` glob.
- `zsh/spectrum.zsh` — 256-color helper arrays (`FG[]`, `BG[]`) and a
  `spectrum_ls` function. Referenced only by the prompt (via `$FG[208]`);
  `spectrum_ls` is never called.
- `zsh/functions/` — autoloaded functions (`c`, `h`, `_c`, `_h`,
  `last_modified`, `verbose_completion`).

Usage pattern: daily zsh user; some of the customization matters (git
branch in prompt, a few aliases), most is inherited cruft.

Probe of tool paths on this machine:

| Path                              | Exists? |
|-----------------------------------|---------|
| `~/git/electronite`               | no      |
| `~/git/flutter`                   | no (actual is `~/bin/flutter/bin/flutter`) |
| `~/.travis`                       | no      |
| `~/.config/composer`              | no      |
| `/usr/local/mysql`                | no      |
| `~/.iterm2_shell_integration.zsh` | no (macOS only) |
| `/usr/local/go`, `~/go`           | no      |
| `~/.asdf`                         | no (but user maintains — keep guard) |
| `~/.nvm`                          | yes     |
| `~/Android/Sdk`                   | yes     |
| `/usr/lib/jvm`                    | yes     |

Starship and antidote are not in Pop!_OS apt. Install via curl/git clone.

## Decisions

1. **Prompt: switch to starship.** Current prompt's git-branch and
   ahead/behind display are defaults in starship (`git_branch` +
   `git_status` + `git_state` modules). One binary, one `eval` line in
   zshrc, no hand-rolled zsh.
2. **Plugins: adopt antidote with three quality-of-life plugins**
   (syntax-highlighting, autosuggestions, history-substring-search).
   Antidote over zinit for simplicity; over oh-my-zsh for minimalism.
3. **Bootstrap cleanup: prune dead tool paths, fix bugs, dedupe, reorganize
   within the same file.** No split into multiple files beyond the existing
   `*.zsh` modules.
4. **Keep existing `*.zsh` modules as-is** except delete `prompt.zsh` and
   `spectrum.zsh`. The other modules (aliases, completion, config,
   functions, git, tmux) stay.
5. **`setxkbmap`: delete from zshrc entirely.** Caps-lock-as-Ctrl is a
   one-time system configuration, not a per-shell side effect. User needs
   to set this via Pop!_OS keyboard settings or `gnome-tweaks`. Not
   something the dotfiles should manage.

## Changes

### `zsh/zshrc.bootstrap` — rewrite

Target shape (~70 lines, down from 145):

```zsh
export DOTFILES=$HOME/.dotfiles
export ZSH=$DOTFILES/zsh

# Env
export EDITOR='vim'
export REPORTTIME=10
export THEME='base16-atelier-lakeside'
export BACKGROUND='dark'
[[ -e ~/.terminfo ]] && export TERMINFO_DIRS=~/.terminfo:/usr/share/terminfo
[[ -d ~/git ]] && export CODE_DIR=~/git
[ -z "$TMUX" ] && export TERM=xterm-256color

# PATH: system dirs first, then user bins, then tool shims last
typeset -U path  # zsh auto-dedupe
path=(
    /usr/local/sbin(N)
    /usr/local/bin(N)
    $DOTFILES/bin
    ~/bin/*/bin(N)
    $path
)

# Source all .zsh modules (glob-safe)
for config ($ZSH/**/*.zsh(N)) source $config

# Machine-local overrides (not in git)
[[ -a ~/.localrc ]] && source ~/.localrc

# Completion system
autoload -U compinit
compinit

# Plugins (antidote)
if [[ -s ~/.antidote/antidote.zsh ]]; then
    source ~/.antidote/antidote.zsh
    antidote load $ZSH/.zsh_plugins.txt
fi

# Tool integrations
[[ -d ~/.asdf ]] && {
    if [[ `uname` == 'Linux' ]]; then
        . $HOME/.asdf/asdf.sh
    else
        . $(brew --prefix asdf)/libexec/asdf.sh
    fi
}

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Node global packages
NPM_PACKAGES="$HOME/.npm-packages"
[[ -d $NPM_PACKAGES/bin ]] && path=($NPM_PACKAGES/bin $path)
[[ -d $NPM_PACKAGES/share/man ]] && export MANPATH="$NPM_PACKAGES/share/man"
[[ -d $NPM_PACKAGES/lib/node_modules ]] && export NODE_PATH="$NPM_PACKAGES/lib/node_modules:$NODE_PATH"

# Android SDK
if [[ -d ~/Android/Sdk ]]; then
    export ANDROID_HOME=~/Android/Sdk
    [[ -d ~/Android/Sdk/tools ]] && path=(~/Android/Sdk/tools $path)
    [[ -d ~/Android/Sdk/platform-tools ]] && path=(~/Android/Sdk/platform-tools $path)
fi

# Java
if [[ -d /usr/lib/jvm ]]; then
    export JAVA_HOME=$(ls -d /usr/lib/jvm/* | grep "[0-9]\+$" | sort --version-sort | tail -n 1)
    path=($path $JAVA_HOME/bin)
fi

# Linux aliases
if [[ `uname` == 'Linux' ]]; then
    alias open=nautilus
    alias xclip='xclip -selection c'
fi

# Base16 colorscheme
BASE16_SHELL="$DOTFILES/.config/base16-shell/scripts/$THEME.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

# Prompt (starship)
command -v starship >/dev/null && eval "$(starship init zsh)"
```

Notes on specific choices:

- `typeset -U path` automatically dedupes PATH entries.
- `(N)` globbing qualifier means "empty if no match" — fixes the phase 1
  regression where the old `*completion.sh` glob crashed.
- Single PATH block replaces ~10 scattered `export PATH=...:$PATH` lines.
- `[ -z "$TMUX" ] && export TERM=xterm-256color` preserves current behavior.
- `command -v starship` guard means the line is a no-op if starship isn't
  installed (graceful degradation).
- Removed: go paths, electronite, flutter block (wrong path), composer,
  mysql, travis, yarn, iterm2, setxkbmap, `did` alias, duplicate
  `ANDROID_HOME`, commented-out dead code.

### `zsh/prompt.zsh` — delete

Superseded by starship.

### `zsh/spectrum.zsh` — delete

Only consumer (`$FG[208]` in `prompt.zsh`) is being deleted; `spectrum_ls`
is never called elsewhere.

### `zsh/.zsh_plugins.txt` — new file

```
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-autosuggestions
zsh-users/zsh-history-substring-search
```

One repo per line, antidote's plain-text format.

### `install.sh` — additions (Linux branch + after-branch)

Add to the Linux branch, after `apt-get autoremove`:

```bash
# starship (not in Pop!_OS apt)
if ! command -v starship >/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi
```

Add after the zshrc setup (outside platform branches, so macOS gets it too):

```bash
# antidote (plugin manager)
if [ ! -d ~/.antidote ]; then
    git clone --depth 1 https://github.com/mattmc3/antidote.git ~/.antidote
fi
```

For macOS (brew block), add `starship` to brew.sh:

```bash
if test ! $(which starship); then
    brew install starship
fi
```

### `CLAUDE.md` — update

The "ZSH configuration architecture" section mentions the glob-sourcing and
the bootstrap's responsibilities. After this rewrite:

- Update the line about "glob unordered" to reflect the new structure.
- Add a mention of starship and antidote.
- Drop mentions of removed items if any are named.

Specifically, the existing quirk-flagged line about `alias vim=vi` vs
`alias vim=nvim` should be removed (both aliases are gone as of earlier
phases).

### Unchanged

- `zsh/aliases.zsh`, `zsh/completion.zsh`, `zsh/config.zsh`,
  `zsh/functions.zsh`, `zsh/git.zsh`, `zsh/tmux.zsh`, `zsh/functions/`
- `zsh/zshrc.bootstrap` is still loaded from `~/.zshrc` via the append
  done in `install.sh`.

## Validation

1. Open a fresh interactive zsh (`zsh -i -c 'echo $PATH'`). No error
   messages. `$PATH` contains expected entries: `/usr/local/sbin`,
   `/usr/local/bin`, `$DOTFILES/bin`, system paths, no duplicates.
2. `command -v starship` returns a path. Prompt shows the starship
   format (when run interactively).
3. In a git repo, starship shows the branch and dirty indicator
   automatically; `cd` into an upstream-ahead branch shows `⇡` markers.
4. `antidote load` runs without error. The three plugins' dirs exist under
   `~/.antidote-cache` or `~/.cache/antidote` (antidote caches them there).
5. `zsh-syntax-highlighting`: `ehco` renders in red, `echo` in green.
6. `zsh-autosuggestions`: after typing a command previously run, a gray
   suggestion appears.
7. `grep setxkbmap /home/joel/.dotfiles/zsh/zshrc.bootstrap` returns nothing
   (the per-shell keyboard remap is gone).
8. `./install.sh` is idempotent: second run skips both starship and
   antidote installs.

## Out of scope

- Switching plugin manager away from antidote.
- Adding more plugins (fzf integration, direnv, etc.) — user can add later
  by editing `.zsh_plugins.txt`.
- Starship custom TOML config — defaults are fine for now; user can
  create `~/.config/starship.toml` later.
- Splitting `zshrc.bootstrap` into multiple files beyond the current
  `*.zsh` module pattern.
- Changes to existing `*.zsh` modules other than deleting `prompt.zsh`
  and `spectrum.zsh`.
- Moving `THEME`/`BACKGROUND` to `.localrc` — keeping them in the bootstrap
  file for simplicity.
- Caps-lock remap setup — user will configure via Pop!_OS keyboard
  settings / `gnome-tweaks` (one-time action, not a dotfile concern).
