# Extras library implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `extras/` directory with 9 opt-in installer scripts + README, remove `install/software.sh`, drop `ruby`/`ruby-dev` from core apt list.

**Architecture:** Personal dotfiles repo. Each script in `extras/` is a standalone executable bash file with its own idempotency guards and platform branching. No wrapper command; discovery via README table.

**Tech Stack:** bash, git, various tool-specific installers (apt, brew, curl, asdf).

**Spec:** `docs/superpowers/specs/2026-04-20-extras-library-design.md`

---

## File Structure

Files touched in this plan:

- **Create:** `extras/` directory with 10 files (1 README + 9 executable scripts)
- **Delete:** `install/software.sh`
- **Modify:** `install.sh` (2 edits: apt list, "Next steps" block)
- **Modify:** `CLAUDE.md` (1 edit: software.sh paragraph)

Unchanged: everything else.

Three commits:
1. Create `extras/` directory with all 10 files
2. Delete `install/software.sh` + update `install.sh`
3. Update `CLAUDE.md`

---

### Task 1: Create `extras/` directory with scripts and README

**Files:**
- Create: `/home/joel/.dotfiles/extras/README.md`
- Create: `/home/joel/.dotfiles/extras/asdf`
- Create: `/home/joel/.dotfiles/extras/crystal`
- Create: `/home/joel/.dotfiles/extras/docker`
- Create: `/home/joel/.dotfiles/extras/fly`
- Create: `/home/joel/.dotfiles/extras/kvm`
- Create: `/home/joel/.dotfiles/extras/python`
- Create: `/home/joel/.dotfiles/extras/ruby`
- Create: `/home/joel/.dotfiles/extras/rust`
- Create: `/home/joel/.dotfiles/extras/vscode`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p /home/joel/.dotfiles/extras
```

- [ ] **Step 2: Write `extras/README.md`**

Use the `Write` tool:

```markdown
# Software library

Opt-in installers for tools you might want but don't need by default.
Each script is self-contained and safe to re-run.

## Usage

    ./extras/<tool>

For example:

    ./extras/rust

## Tools

| Script    | Description                                           |
|-----------|-------------------------------------------------------|
| `asdf`    | Multi-language version manager                        |
| `crystal` | Crystal programming language (via asdf)               |
| `docker`  | Docker Engine (Linux) / Docker Desktop (macOS)        |
| `fly`     | Fly.io CLI (flyctl)                                   |
| `kvm`     | KVM + QEMU + libvirt + virt-manager (Linux only)      |
| `python`  | Python (latest stable, via asdf)                      |
| `ruby`    | Ruby (latest stable, via asdf)                        |
| `rust`    | Rust toolchain (via rustup)                           |
| `vscode`  | Visual Studio Code editor                             |

## Adding a new tool

Drop a new executable script here and add a row to the table above.
Each script should:

- Begin with `#!/usr/bin/env bash` and `set -e`
- Branch on `uname -s` for Linux / Darwin
- Be idempotent (safe to re-run — guard with `command -v X` or
  directory/file existence checks)
- Print a message about any post-install manual steps (group changes,
  PATH additions, BIOS settings, etc.)
```

- [ ] **Step 3: Write `extras/asdf`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# asdf — multi-language version manager
set -e

if [ -d ~/.asdf ]; then
    echo "asdf already installed at ~/.asdf"
    exit 0
fi

echo "Installing asdf"
git clone https://github.com/asdf-vm/asdf.git ~/.asdf
(cd ~/.asdf && git checkout "$(git describe --abbrev=0 --tags)")

echo "asdf installed. Already wired into zshrc.bootstrap — open a new"
echo "shell or 'source ~/.asdf/asdf.sh' to start using it."
```

- [ ] **Step 4: Write `extras/crystal`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# crystal — Crystal programming language (via asdf)
set -e

if [ ! -d ~/.asdf ]; then
    echo "Installing asdf (required for crystal)"
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf
    (cd ~/.asdf && git checkout "$(git describe --abbrev=0 --tags)")
fi

. ~/.asdf/asdf.sh

if ! asdf plugin list 2>/dev/null | grep -qx crystal; then
    echo "Adding asdf crystal plugin"
    asdf plugin add crystal
fi

echo "Installing latest crystal"
asdf install crystal latest
```

- [ ] **Step 5: Write `extras/docker`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# docker — Docker Engine (Linux) / Docker Desktop (macOS)
set -e

if command -v docker >/dev/null; then
    echo "docker already installed: $(command -v docker)"
    exit 0
fi

case "$(uname -s)" in
    Linux)
        echo "Installing Docker Engine via get.docker.com"
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$USER"
        echo ""
        echo "Docker installed. Log out and back in for the 'docker' group to take effect."
        ;;
    Darwin)
        if ! command -v brew >/dev/null; then
            echo "Homebrew required. Install via 'install/brew.sh' first." >&2
            exit 1
        fi
        brew install --cask docker
        echo ""
        echo "Docker Desktop installed. Launch it from Applications once to finish setup."
        ;;
    *)
        echo "Unsupported platform." >&2
        exit 1
        ;;
esac
```

- [ ] **Step 6: Write `extras/fly`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# fly — Fly.io CLI (flyctl)
set -e

if command -v fly >/dev/null || command -v flyctl >/dev/null; then
    echo "fly already installed"
    exit 0
fi

echo "Installing flyctl"
curl -L https://fly.io/install.sh | sh

echo ""
echo "flyctl installed to ~/.fly/. The installer appends a PATH export"
echo "to your shell rc — open a new shell or 'exec zsh' to pick it up."
```

- [ ] **Step 7: Write `extras/kvm`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# kvm — KVM + QEMU + libvirt + virt-manager (Linux only)
set -e

case "$(uname -s)" in
    Linux)
        if ! command -v apt-get >/dev/null; then
            echo "This script requires apt (Debian/Ubuntu/Pop!_OS)." >&2
            exit 1
        fi
        echo "Installing KVM + QEMU + libvirt + virt-manager"
        sudo apt-get update
        sudo apt-get -y install \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            bridge-utils \
            virt-manager \
            ovmf
        sudo systemctl enable --now libvirtd
        sudo usermod -aG libvirt,kvm "$USER"
        echo ""
        echo "KVM stack installed. Next steps:"
        echo "  1. Log out and back in for libvirt/kvm group membership."
        echo "  2. Verify hardware virtualization is enabled in BIOS: run 'kvm-ok'."
        echo "     (If 'kvm-ok' is missing, 'sudo apt install cpu-checker')"
        echo "  3. Launch 'virt-manager' for a GUI."
        ;;
    Darwin)
        echo "KVM is Linux-only. For macOS virtualization, consider UTM:"
        echo "  brew install --cask utm"
        exit 0
        ;;
    *)
        echo "Unsupported platform." >&2
        exit 1
        ;;
esac
```

- [ ] **Step 8: Write `extras/python`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# python — Python (latest stable, via asdf)
set -e

if [ ! -d ~/.asdf ]; then
    echo "Installing asdf (required for python)"
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf
    (cd ~/.asdf && git checkout "$(git describe --abbrev=0 --tags)")
fi

. ~/.asdf/asdf.sh

if ! asdf plugin list 2>/dev/null | grep -qx python; then
    echo "Adding asdf python plugin"
    asdf plugin add python
fi

echo "Installing latest python (this compiles from source — 5-10 min)"
asdf install python latest
asdf global python latest
```

- [ ] **Step 9: Write `extras/ruby`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# ruby — Ruby (latest stable, via asdf)
set -e

if [ ! -d ~/.asdf ]; then
    echo "Installing asdf (required for ruby)"
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf
    (cd ~/.asdf && git checkout "$(git describe --abbrev=0 --tags)")
fi

. ~/.asdf/asdf.sh

if ! asdf plugin list 2>/dev/null | grep -qx ruby; then
    echo "Adding asdf ruby plugin"
    asdf plugin add ruby
fi

echo "Installing latest ruby (this compiles from source — a few minutes)"
asdf install ruby latest
asdf global ruby latest
```

- [ ] **Step 10: Write `extras/rust`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# rust — Rust toolchain (via rustup)
set -e

if command -v rustup >/dev/null; then
    echo "rustup already installed. Update with 'rustup update'."
    exit 0
fi

echo "Installing Rust via rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo ""
echo "Rust installed to ~/.cargo. Open a new shell or"
echo "'source ~/.cargo/env' to use it now."
```

- [ ] **Step 11: Write `extras/vscode`**

Use the `Write` tool:

```bash
#!/usr/bin/env bash
# vscode — Visual Studio Code editor
set -e

if command -v code >/dev/null; then
    echo "VS Code already installed: $(command -v code)"
    exit 0
fi

case "$(uname -s)" in
    Linux)
        echo "Installing Visual Studio Code"
        curl -L "https://go.microsoft.com/fwlink/?LinkID=760868" -o /tmp/code_amd64.deb
        sudo apt install -y /tmp/code_amd64.deb
        rm /tmp/code_amd64.deb
        ;;
    Darwin)
        if ! command -v brew >/dev/null; then
            echo "Homebrew required. Install via 'install/brew.sh' first." >&2
            exit 1
        fi
        brew install --cask visual-studio-code
        ;;
    *)
        echo "Unsupported platform." >&2
        exit 1
        ;;
esac
```

- [ ] **Step 12: Make all 9 scripts executable**

```bash
chmod +x /home/joel/.dotfiles/extras/asdf \
         /home/joel/.dotfiles/extras/crystal \
         /home/joel/.dotfiles/extras/docker \
         /home/joel/.dotfiles/extras/fly \
         /home/joel/.dotfiles/extras/kvm \
         /home/joel/.dotfiles/extras/python \
         /home/joel/.dotfiles/extras/ruby \
         /home/joel/.dotfiles/extras/rust \
         /home/joel/.dotfiles/extras/vscode
```

Verify:
```bash
ls -l /home/joel/.dotfiles/extras/ | awk 'NR>1 {print $1, $NF}'
```

Expected: all 9 scripts should show `-rwxr-xr-x` permissions; README.md should show `-rw-r--r--`.

- [ ] **Step 13: Syntax-check every script**

```bash
for f in /home/joel/.dotfiles/extras/{asdf,crystal,docker,fly,kvm,python,ruby,rust,vscode}; do
    bash -n "$f" || echo "SYNTAX ERROR in $f"
done
echo "done"
```

Expected output: just `done` with no SYNTAX ERROR lines.

- [ ] **Step 14: Commit**

```bash
git -C /home/joel/.dotfiles add extras/
git -C /home/joel/.dotfiles commit -m "$(cat <<'EOF'
phase 4: add extras/ opt-in software library

Nine self-contained installer scripts for tools you might occasionally
want but don't need in the core install:

- asdf       — multi-language version manager
- crystal    — Crystal language (via asdf)
- docker     — Docker Engine (Linux) / Docker Desktop (macOS)
- fly        — Fly.io CLI (flyctl)
- kvm        — KVM + QEMU + libvirt + virt-manager (Linux)
- python     — Python (via asdf)
- ruby       — Ruby (via asdf)
- rust       — Rust toolchain (via rustup)
- vscode     — Visual Studio Code editor

Each script is idempotent, handles its own platform branching, and
bootstraps its dependencies (asdf for the three language scripts).
Discovery via extras/README.md table; no wrapper command.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify: `git -C /home/joel/.dotfiles log --oneline -1` shows the new commit. `git -C /home/joel/.dotfiles show --stat HEAD` lists 10 files added under `extras/`.

---

### Task 2: Delete `install/software.sh` and update `install.sh`

**Files:**
- Delete: `/home/joel/.dotfiles/install/software.sh`
- Modify: `/home/joel/.dotfiles/install.sh` (remove ruby/ruby-dev from apt list; update "Next steps" block)

- [ ] **Step 1: Delete `install/software.sh`**

```bash
git -C /home/joel/.dotfiles rm install/software.sh
```

Expected output: `rm 'install/software.sh'`.

- [ ] **Step 2: Remove `ruby` and `ruby-dev` from `install.sh` apt list**

Use the `Edit` tool on `/home/joel/.dotfiles/install.sh`.

- old_string:
```
	sudo apt-get -y install \
		build-essential \
		lm-sensors \
		neofetch \
		resilio-sync \
		ruby \
		ruby-dev \
		snapd \
		tmux \
		unzip \
		vim-gui-common \
		vim-runtime \
		xclip \
		zsh
```

- new_string:
```
	sudo apt-get -y install \
		build-essential \
		lm-sensors \
		neofetch \
		resilio-sync \
		snapd \
		tmux \
		unzip \
		vim-gui-common \
		vim-runtime \
		xclip \
		zsh
```

- [ ] **Step 3: Update the "Next steps" block in `install.sh`**

Use the `Edit` tool on `/home/joel/.dotfiles/install.sh`.

- old_string:
```
	echo "Optional:"
	echo "  - Run $DOTFILES/install/software.sh for VS Code, asdf, Crystal."
```

- new_string:
```
	echo "Optional:"
	echo "  - Browse optional tools in $DOTFILES/extras/ (asdf, crystal,"
	echo "    docker, fly, kvm, python, ruby, rust, vscode)."
```

- [ ] **Step 4: Syntax-check `install.sh`**

```bash
bash -n /home/joel/.dotfiles/install.sh
```

Expected: empty output.

- [ ] **Step 5: Verify status**

```bash
git -C /home/joel/.dotfiles status --short
```

Expected output:
```
M  install.sh
D  install/software.sh
```

Only those two entries. If anything else appears, stop and report.

- [ ] **Step 6: Commit**

```bash
git -C /home/joel/.dotfiles add install.sh && \
  git -C /home/joel/.dotfiles commit -m "$(cat <<'EOF'
phase 4: delete install/software.sh, remove ruby from core apt list

software.sh's three tools (asdf, crystal, vscode) are now in extras/.
ruby and ruby-dev move to extras/ruby since they're a dev-language
dependency, not a core shell need — consistent with the YAGNI pattern
applied to vim, tmux, and zsh.

Also update install.sh's "Next steps" block to point at extras/ instead
of the deleted software.sh.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify: `git -C /home/joel/.dotfiles log --oneline -2` shows both phase 4 commits.

---

### Task 3: Update `CLAUDE.md`

**Files:**
- Modify: `/home/joel/.dotfiles/CLAUDE.md`

- [ ] **Step 1: Replace the `install/software.sh` paragraph**

Use the `Edit` tool on `/home/joel/.dotfiles/CLAUDE.md`.

- old_string:
```
`install/software.sh` is a separate, manually-run script for optional tools (VS Code, asdf, Crystal) — not called from `install.sh`. Invoke directly when you want those tools.
```

- new_string:
```
Optional tools live in `extras/` (asdf, crystal, docker, fly, kvm, python, ruby, rust, vscode). Each is a self-contained, idempotent install script. Run `./extras/<tool>` to install one; `extras/README.md` lists what's available. Not called from `install.sh`.
```

- [ ] **Step 2: Verify no stale references to `software.sh` remain**

```bash
grep -n software.sh /home/joel/.dotfiles/CLAUDE.md /home/joel/.dotfiles/README.md 2>&1
echo "exit: $?"
```

Expected: either empty output with `exit: 1` (no matches) or only false positives. If real references remain in CLAUDE.md or README.md, note them — but do not fix in this task unless trivially aligned with the rewrite.

- [ ] **Step 3: Commit**

```bash
git -C /home/joel/.dotfiles add CLAUDE.md && \
  git -C /home/joel/.dotfiles commit -m "$(cat <<'EOF'
phase 4: CLAUDE.md - point at extras/ library

Replace the install/software.sh paragraph with a description of the
new extras/ directory. Lists the 9 tools and documents the run pattern.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify: `git -C /home/joel/.dotfiles status` is clean. `git log --oneline -3` shows all three phase 4 commits on top.

---

### Task 4: Final integration check + clear memory

Inline verification, no commit.

- [ ] **Step 1: Smoke-test one script**

Pick `extras/fly` (user has fly already installed on this machine, so it should early-exit cleanly):

```bash
/home/joel/.dotfiles/extras/fly
```

Expected output: `fly already installed` and exit 0. It must NOT attempt to download or install anything.

- [ ] **Step 2: Verify README table is in sync with filenames**

```bash
ls /home/joel/.dotfiles/extras/ | grep -v '^README.md$' | sort > /tmp/actual-files
grep -E '^\| `[a-z]+`' /home/joel/.dotfiles/extras/README.md | awk -F'`' '{print $2}' | sort > /tmp/readme-entries
diff /tmp/actual-files /tmp/readme-entries && echo "in sync"
rm /tmp/actual-files /tmp/readme-entries
```

Expected: `in sync`. If diff shows differences, either a script was added without a README row or the README lists something that doesn't exist.

- [ ] **Step 3: Remove the now-resolved memory note**

Phase 4 was the thing that project memory was about. Delete the memory file:

```bash
rm ~/.claude/projects/-home-joel--dotfiles/memory/project_software_library.md
```

Then update `MEMORY.md`:

Use the `Edit` tool on `/home/joel/.claude/projects/-home-joel--dotfiles/memory/MEMORY.md`.

- old_string:
```
- [Setup scripts should be idempotent](feedback_idempotent_setup.md) — install/bootstrap scripts in the dotfiles repo must be safe to re-run
- [Planned software library](project_software_library.md) — future addition: browsable opt-in tool library, to be built after main cleanup
```

- new_string:
```
- [Setup scripts should be idempotent](feedback_idempotent_setup.md) — install/bootstrap scripts in the dotfiles repo must be safe to re-run
```

- [ ] **Step 4: Done**

If the fly smoke test passes, the README table is in sync, and the memory file is removed, phase 4 is complete.

---

## Rollback

Each commit is independently revertable:

```bash
git -C /home/joel/.dotfiles log --oneline | grep 'phase 4'
git -C /home/joel/.dotfiles revert <commit-sha>
```

Reverting Task 1 removes the entire library. Reverting Task 2 restores `install/software.sh` and puts ruby back in the core apt list. Reverting Task 3 restores the old CLAUDE.md paragraph.
