# Zsh cleanup implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Slim `zshrc.bootstrap` from 145 to ~70 lines, switch prompt from hand-rolled to starship, add antidote with 3 quality-of-life plugins.

**Architecture:** Personal dotfiles repo. Single bootstrap file loaded from `~/.zshrc`. Plugins via antidote (plain-text plugin list). Prompt via starship binary. No test suite — verification is `zsh -n`, opening a fresh zsh, and spot-checking behavior.

**Tech Stack:** zsh, antidote, starship, bash (install script), git.

**Spec:** `docs/superpowers/specs/2026-04-20-zsh-cleanup-design.md`

---

## File Structure

Files touched in this plan:

- **Rewrite:** `zsh/zshrc.bootstrap` (145 → ~70 lines)
- **Delete:** `zsh/prompt.zsh`, `zsh/spectrum.zsh`
- **Create:** `zsh/.zsh_plugins.txt` (3 lines)
- **Modify:** `install.sh` (add starship + antidote installs, guarded)
- **Modify:** `install/brew.sh` (add starship for macOS)
- **Modify:** `CLAUDE.md` (reflect new state across several sections)

Unchanged: `zsh/aliases.zsh`, `zsh/completion.zsh`, `zsh/config.zsh`, `zsh/functions.zsh`, `zsh/git.zsh`, `zsh/tmux.zsh`, `zsh/functions/`.

Three commits:
1. Install-script updates (starship + antidote idempotent installs)
2. Bootstrap rewrite + plugins file + deletions
3. CLAUDE.md refresh

---

### Task 1: Add starship + antidote to install scripts, install locally

**Files:**
- Modify: `/home/joel/.dotfiles/install.sh`
- Modify: `/home/joel/.dotfiles/install/brew.sh`

This task commits the install-script changes AND runs the install locally (so Task 2's new bootstrap has working starship + antidote in this session).

- [ ] **Step 1: Add starship to `install/brew.sh` (macOS path)**

Use the `Edit` tool on `/home/joel/.dotfiles/install/brew.sh`.

- old_string:
```
if test ! $(which ack); then
    brew install ack
fi
```

- new_string:
```
if test ! $(which ack); then
    brew install ack
fi

if test ! $(which starship); then
    brew install starship
fi
```

- [ ] **Step 2: Add starship install to `install.sh` Linux branch**

Use the `Edit` tool on `/home/joel/.dotfiles/install.sh`.

- old_string:
```
	sudo apt-get -y autoremove

	# Configure resilio sync
```

- new_string:
```
	sudo apt-get -y autoremove

	# starship prompt (not in Pop!_OS apt)
	if ! command -v starship >/dev/null; then
		curl -sS https://starship.rs/install.sh | sh -s -- --yes
	fi

	# Configure resilio sync
```

- [ ] **Step 3: Add antidote clone outside platform branches**

The existing nvm clone uses the same pattern; antidote goes right after it.

Use the `Edit` tool on `/home/joel/.dotfiles/install.sh`.

- old_string:
```
# Install nvm via git clone (idempotent; shared between macOS and Linux)
if [ ! -d ~/.nvm ]; then
	echo "Installing Node Version Manager (nvm) $NVM_VERSION"
	git clone https://github.com/nvm-sh/nvm.git ~/.nvm
	(cd ~/.nvm && git checkout "$NVM_VERSION")
fi
```

- new_string:
```
# Install nvm via git clone (idempotent; shared between macOS and Linux)
if [ ! -d ~/.nvm ]; then
	echo "Installing Node Version Manager (nvm) $NVM_VERSION"
	git clone https://github.com/nvm-sh/nvm.git ~/.nvm
	(cd ~/.nvm && git checkout "$NVM_VERSION")
fi

# Install antidote plugin manager (idempotent; shared between macOS and Linux)
if [ ! -d ~/.antidote ]; then
	echo "Installing antidote"
	git clone --depth 1 https://github.com/mattmc3/antidote.git ~/.antidote
fi
```

- [ ] **Step 4: Syntax-check the modified scripts**

```bash
bash -n /home/joel/.dotfiles/install.sh
bash -n /home/joel/.dotfiles/install/brew.sh
```

Expected: empty output (no syntax errors) from both.

- [ ] **Step 5: Install starship locally (this session only; not committed)**

Starship isn't in Pop!_OS apt. Install via the official script:

```bash
if ! command -v starship >/dev/null; then
	curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi
command -v starship
```

Expected final output: path like `/usr/local/bin/starship`.

If `curl | sh` requires sudo for the install location, the starship installer will prompt. On Pop!_OS it typically writes to `/usr/local/bin/` which needs sudo; the installer handles this interactively.

- [ ] **Step 6: Install antidote locally (this session only; not committed)**

```bash
if [ ! -d ~/.antidote ]; then
	git clone --depth 1 https://github.com/mattmc3/antidote.git ~/.antidote
fi
ls ~/.antidote/antidote.zsh
```

Expected final output: `/home/joel/.antidote/antidote.zsh` exists.

- [ ] **Step 7: Commit the install-script changes**

```bash
git -C /home/joel/.dotfiles add install.sh install/brew.sh
git -C /home/joel/.dotfiles commit -m "$(cat <<'EOF'
phase 2c: add starship + antidote to install scripts

starship: prompt generator (modern replacement for hand-rolled prompt.zsh).
  Not in Pop!_OS apt — install via official curl script on Linux,
  brew install on macOS. Idempotent via command -v guard.
antidote: zsh plugin manager. Git-clone to ~/.antidote, idempotent via
  directory check. Shared between macOS and Linux (no brew version needed).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify: `git -C /home/joel/.dotfiles log --oneline -1` shows the new commit.

---

### Task 2: Rewrite `zshrc.bootstrap`, create `.zsh_plugins.txt`, delete `prompt.zsh` and `spectrum.zsh`

**Files:**
- Rewrite: `/home/joel/.dotfiles/zsh/zshrc.bootstrap`
- Create: `/home/joel/.dotfiles/zsh/.zsh_plugins.txt`
- Delete: `/home/joel/.dotfiles/zsh/prompt.zsh`
- Delete: `/home/joel/.dotfiles/zsh/spectrum.zsh`

- [ ] **Step 1: Confirm current state**

```bash
wc -l /home/joel/.dotfiles/zsh/zshrc.bootstrap /home/joel/.dotfiles/zsh/prompt.zsh /home/joel/.dotfiles/zsh/spectrum.zsh
```

Expected line counts: bootstrap ~145, prompt ~70, spectrum ~28. If bootstrap is already ~70, the rewrite has happened — stop and ask.

- [ ] **Step 2: Write the new `zshrc.bootstrap`**

Use the `Write` tool to replace the entire contents of `/home/joel/.dotfiles/zsh/zshrc.bootstrap` with:

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

# PATH: zsh auto-dedupes; (N) means "empty if no match"
typeset -U path
path=(
    /usr/local/sbin(N)
    /usr/local/bin(N)
    $DOTFILES/bin
    ~/.local/bin(N)
    ~/bin/*/bin(N)
    $path
)

# Source all .zsh modules (null-glob safe)
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

# asdf
if [[ -d ~/.asdf ]]; then
    if [[ `uname` == 'Linux' ]]; then
        . $HOME/.asdf/asdf.sh
    else
        . $(brew --prefix asdf)/libexec/asdf.sh
    fi
fi

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

# Linux-only aliases
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

- [ ] **Step 3: Create `.zsh_plugins.txt`**

Use the `Write` tool to create `/home/joel/.dotfiles/zsh/.zsh_plugins.txt` with:

```
zsh-users/zsh-autosuggestions
zsh-users/zsh-history-substring-search
zsh-users/zsh-syntax-highlighting
```

Order matters: syntax-highlighting loads last because it wraps ZLE widgets.

- [ ] **Step 4: Delete `prompt.zsh` and `spectrum.zsh`**

```bash
rm /home/joel/.dotfiles/zsh/prompt.zsh /home/joel/.dotfiles/zsh/spectrum.zsh
```

Verify:
```bash
ls /home/joel/.dotfiles/zsh/
```

Expected (no prompt.zsh, no spectrum.zsh):
```
aliases.zsh  completion.zsh  config.zsh  functions  functions.zsh  git.zsh  tmux.zsh  .zsh_plugins.txt  zshrc.bootstrap
```

(The `.zsh_plugins.txt` file is a dotfile so may not show without `-A`; run `ls -A` to confirm.)

- [ ] **Step 5: Sanity-check zsh can parse the new bootstrap**

```bash
zsh -n /home/joel/.dotfiles/zsh/zshrc.bootstrap
```

Expected: empty output (no syntax errors). If you see an error like "parse error near", the rewrite has a bug — diff against Step 2 to find the difference.

- [ ] **Step 6: Start a fresh interactive zsh and verify no error output on startup**

```bash
zsh -ic 'exit' 2>&1 | head -20
```

Expected: either empty output, or only benign startup messages (e.g., vcs info hints). Specifically, you must NOT see:
- `no matches found` errors (the phase 1 regression we're fixing)
- `command not found` for any config line
- `parse error`

If you see errors, the new bootstrap or one of the modules has an issue.

- [ ] **Step 7: Verify PATH setup and starship integration**

```bash
zsh -ic 'echo $PATH; command -v starship; command -v antidote'
```

Expected:
- `$PATH` contains `/usr/local/sbin`, `/usr/local/bin`, `/home/joel/.dotfiles/bin`, plus any `~/bin/*/bin` matches, no duplicate entries.
- `command -v starship` returns a path.
- `command -v antidote` returns `antidote` (it's a zsh function from antidote.zsh, so `command -v` will just show the name).

- [ ] **Step 8: Verify plugins loaded**

```bash
zsh -ic 'type _zsh_autosuggest_start _zsh_highlight history-substring-search-up' 2>&1
```

Expected: three lines, each describing a shell function (e.g., `_zsh_autosuggest_start is a shell function from ...`). Not "not found" for any of the three.

- [ ] **Step 9: Commit**

```bash
git -C /home/joel/.dotfiles add zsh/zshrc.bootstrap zsh/.zsh_plugins.txt && \
  git -C /home/joel/.dotfiles rm zsh/prompt.zsh zsh/spectrum.zsh && \
  git -C /home/joel/.dotfiles commit -m "$(cat <<'EOF'
phase 2c: slim zshrc.bootstrap, switch to starship + antidote

Bootstrap: 145 → ~70 lines. Delete dead tool paths (go, electronite,
composer, mysql, travis, yarn, iterm2, flutter-block — flutter is picked
up by the ~/bin/*/bin scanner). Fix phase 1 glob regression with (N)
nullglob qualifier. Drop per-shell setxkbmap; caps-lock-as-Ctrl is a
system setting, not a per-shell side effect. Drop did alias. Dedupe
ANDROID_HOME. Consolidate PATH into one array using typeset -U for
auto-dedup.

Prompt: replace hand-rolled prompt.zsh with starship. Branch, ahead/behind
arrows, and dirty indicator are starship defaults.

Plugins: add antidote with zsh-autosuggestions, zsh-history-substring-search,
and zsh-syntax-highlighting (loaded in that order — syntax-highlighting
must be last per its README).

Delete spectrum.zsh (FG/BG arrays only used by prompt.zsh; spectrum_ls
function never called).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify: `git -C /home/joel/.dotfiles status --short` is empty. `git log --oneline -3` shows this commit on top of the Task 1 commit.

---

### Task 3: Update `CLAUDE.md` to reflect new state

**Files:**
- Modify: `/home/joel/.dotfiles/CLAUDE.md`

This task catches multiple stale references across phases 1, 3, 2a, 2b, 2c.

- [ ] **Step 1: Update the install.sh description (install/nvm.sh is gone; ack is gone; nvm moved)**

Use the `Edit` tool on `/home/joel/.dotfiles/CLAUDE.md`.

- old_string:
```
3. On macOS: sources `install/brew.sh`, `install/osx.sh`, `install/nvm.sh`.
4. On Linux: installs apt packages (zsh, tmux, ack, vim, build-essential, resilio-sync, etc.), installs nvm, creates `~/.vim-tmp`.
5. Always: creates `~/bin`, `chsh` to zsh, appends `source $DOTFILES/zsh/zshrc.bootstrap` to `~/.zshrc`, runs `nvm install stable`.
```

- new_string:
```
3. On macOS: sources `install/brew.sh`, `install/osx.sh`.
4. On Linux: installs apt packages (zsh, tmux, vim, build-essential, resilio-sync, etc.), creates `~/.vim-tmp`, installs starship via the official curl script.
5. Always (both platforms): creates `~/bin`, clones nvm, clones antidote, guarded by existence checks (idempotent); `chsh` to zsh (if not already), appends `source $DOTFILES/zsh/zshrc.bootstrap` to `~/.zshrc` (if not already there), runs `nvm install stable`.
```

- [ ] **Step 2: Update the `install/software.sh` paragraph**

- old_string:
```
`install/software.sh` is a separate, manually-run Linux script for Keybase, VS Code, asdf, Crystal — not called from `install.sh`.
```

- new_string:
```
`install/software.sh` is a separate, manually-run script for optional tools (VS Code, asdf, Crystal) — not called from `install.sh`. Invoke directly when you want those tools.
```

- [ ] **Step 3: Rewrite the "ZSH configuration architecture" section**

- old_string:
```
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
```

- new_string:
```
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
```

- [ ] **Step 4: Rewrite the "Vim / Neovim" section**

- old_string:
```
## Vim / Neovim

`vimrc.symlink` → `~/.vimrc` and `vim.symlink` → `~/.vim`. Plugins are managed with vim-plug; first-time setup is `nvim +PlugInstall` (or `vim +PlugInstall`). The README describes a shared config for both, but note `zsh/aliases.zsh` aliases `vim=nvim` while `zshrc.bootstrap` has `alias vim=vi` — the aliases file wins because it's sourced after bootstrap via the glob.
```

- new_string:
```
## Vim

`vimrc.symlink` → `~/.vimrc` and `vim.symlink` → `~/.vim`. Plugins are managed with vim-plug; first-time setup is `vim +PlugInstall`. Two plugins: `base16-vim` (colorscheme, matches `$THEME` from the shell) and `vim-fugitive` (git). The config is slim (~50 lines) — vim is used for git commits and quick edits, not full IDE work. Neovim is NOT installed by this repo.
```

- [ ] **Step 5: Update the "Platform-conditional code" section**

- old_string:
```
Most scripts branch on `uname` or `$(uname -s)`. When editing cross-platform code, preserve both branches — this repo is used on both Pop!_OS/Linux and macOS. Linux-specific concerns in `install.sh` include resilio-sync repo setup, apt package list, and `setxkbmap` for caps-lock remap.
```

- new_string:
```
Most scripts branch on `uname` or `$(uname -s)`. When editing cross-platform code, preserve both branches — this repo is used on both Pop!_OS/Linux and macOS. Linux-specific concerns in `install.sh` include resilio-sync repo setup and the apt package list. Caps-lock-as-Ctrl is NOT managed by this repo — configure via Pop!_OS keyboard settings / `gnome-tweaks` as a one-time system action.
```

- [ ] **Step 6: Verify the file still reads coherently**

```bash
cat /home/joel/.dotfiles/CLAUDE.md | head -80
```

Skim for contradictions or leftover references to deleted things (nvm.sh, ack, Keybase, setxkbmap, `vim=nvim` alias, prompt.zsh, spectrum.zsh). If any remain, search and fix.

- [ ] **Step 7: Commit**

```bash
git -C /home/joel/.dotfiles add CLAUDE.md
git -C /home/joel/.dotfiles commit -m "$(cat <<'EOF'
phase 2c: refresh CLAUDE.md after zsh cleanup

Update install.sh description: install/nvm.sh no longer exists (phase 3),
ack dropped (phase 1), starship added (phase 2c), antidote clone added.
Update ZSH configuration architecture: reflects consolidated PATH,
(N) glob qualifiers, antidote plugin loading, starship prompt init.
Rewrite Vim/Neovim section: no more vim=nvim alias confusion, plain vim
only, slim config.
Update Platform-conditional: setxkbmap is gone; caps-lock is a system
setting now.
install/software.sh: drop Keybase (removed in phase 3).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify: `git -C /home/joel/.dotfiles status` is clean. `git log --oneline -4` shows all three phase 2c commits on top.

---

### Task 4: Final integration check

Inline verification, no commit.

- [ ] **Step 1: Fresh zsh smoke test**

```bash
zsh -ic 'echo "---PATH---"; echo $PATH | tr ":" "\n" | nl; echo "---starship---"; command -v starship; echo "---antidote---"; command -v antidote; echo "---widgets---"; functions -M 2>/dev/null | head; echo "---done---"' 2>&1
```

Expected:
- `---PATH---` followed by a numbered list with `/usr/local/sbin`, `/usr/local/bin`, `$DOTFILES/bin`, no obvious duplicates.
- `---starship---` followed by a path.
- `---antidote---` followed by `antidote`.
- `---widgets---` either empty or listing some widgets (doesn't matter).
- `---done---` at the end. No error output anywhere in the stream.

- [ ] **Step 2: Confirm the glob regression is fixed**

```bash
zsh -ic 'exit' 2>&1 | grep -i 'no matches found'
```

Expected: empty output (grep exits 1 because nothing matched). If anything prints, the (N) nullglob fix didn't take effect.

- [ ] **Step 3: Spot-check that a plugin works**

Can't easily exercise interactive behavior from the command line, but verify the plugin functions are defined:

```bash
zsh -ic 'type _zsh_autosuggest_start; type _zsh_highlight; type history-substring-search-up'
```

Expected: each returns "`<name> is a shell function`" (or similar). If any returns "not found", antidote didn't load that plugin.

- [ ] **Step 4: Update deferred-regression memory**

The user's memory file at `~/.claude/projects/-home-joel--dotfiles/memory/project_zsh_regression.md` was marked deferred to phase 2c. Mark it resolved:

```bash
rm ~/.claude/projects/-home-joel--dotfiles/memory/project_zsh_regression.md
```

Then update the `MEMORY.md` index — remove the line pointing to the deleted file. Use the `Edit` tool on `/home/joel/.claude/projects/-home-joel--dotfiles/memory/MEMORY.md`:

- old_string:
```
- [Planned software library](project_software_library.md) — future addition: browsable opt-in tool library, to be built after main cleanup
- [zsh completion.sh glob regression (deferred)](project_zsh_regression.md) — fix zshrc.bootstrap:32 null-glob during phase 2c
```

- new_string:
```
- [Planned software library](project_software_library.md) — future addition: browsable opt-in tool library, to be built after main cleanup
```

The new_string has no trailing newline after the last bullet — which matches the original file's state where the zsh-regression line was the last line and was newline-terminated.

- [ ] **Step 5: Done**

If all three spot-checks pass and the memory is cleaned up, phase 2c is complete.

---

## Rollback

If something breaks after landing, each commit is independently revertable:

```bash
git -C /home/joel/.dotfiles log --oneline | grep 'phase 2c'
git -C /home/joel/.dotfiles revert <commit-sha>
```

Reverting Task 2's commit restores the old prompt.zsh + spectrum.zsh + old bootstrap. Reverting Task 1 leaves starship/antidote installed on disk but stops the install scripts from trying to install them.

If antidote misbehaves (plugin loading errors), comment out the `source ~/.antidote/antidote.zsh` block in `zshrc.bootstrap` for a quick escape hatch while debugging.
