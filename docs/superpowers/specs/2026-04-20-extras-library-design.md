# Software library (`extras/`) — design

Phase 4 of the multi-phase dotfiles cleanup. Phases 1-3 and 2a-2c are
complete; this is the final phase.

## Context

`install/software.sh` today is a monolithic shell script that, when
invoked manually, installs VS Code, asdf, and Crystal in sequence.
There's no way to install just one, no clear way to browse what's
available, and the pattern doesn't scale as the user adds more tools.

User want (recorded in the `project_software_library` memory note from
2026-04-20): a browsable "library" of optional software where each tool
is its own installable unit, easy to discover and run individually.

Current user usage:
- Has `~/.asdf` installation (was present at some point, currently absent
  on this machine — the asdf guard in `zshrc.bootstrap` is still correct)
- Uses `~/.fly/bin` (fly.io CLI present on current machine)
- Not currently running docker, rust, crystal, or vscode regularly — but
  wants them available on demand.

## Decisions

1. **New directory `extras/` at repo root.** Lives alongside `bin/`,
   `zsh/`, `vim.symlink/`, etc. "Extras" conveys opt-in and friendly.
2. **One executable script per tool**, no extension, shebang
   `#!/usr/bin/env bash`. Each is self-contained (handles its own
   platform branching, idempotency, and dependencies).
3. **No wrapper command.** Discovery is via `ls extras/` and
   `extras/README.md`. If the library grows enough that a menu helps,
   a 3-line lister can be added later.
4. **Each script is self-bootstrapping.** Three of the scripts
   (`crystal`, `python`, `ruby`) need asdf; each installs asdf if
   missing rather than calling `extras/asdf` as a sub-script. Keeps
   scripts independent at the cost of ~5 lines of duplication.
5. **Delete `install/software.sh`.** Its three tools (asdf, crystal,
   vscode) become three `extras/` scripts. No backward-compatibility
   shim.
6. **Remove `ruby` and `ruby-dev` from `install.sh`'s apt list.** Ruby
   moves to `extras/ruby` (via asdf) since it's a dev-language
   dependency, not a core shell need.

## Changes

### New directory `extras/`

```
extras/
├── README.md
├── asdf
├── crystal
├── docker
├── fly
├── kvm
├── python
├── ruby
├── rust
└── vscode
```

### `extras/README.md`

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

### `extras/asdf`

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

### `extras/crystal`

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
asdf global crystal latest
```

### `extras/docker`

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

### `extras/fly`

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

### `extras/kvm`

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

### `extras/python`

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

### `extras/ruby`

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

### `extras/rust`

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

### `extras/vscode`

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

### Delete `install/software.sh`

Its VS Code, asdf, and crystal install blocks are superseded by
`extras/vscode`, `extras/asdf`, and `extras/crystal` respectively.

### Update `install.sh`

Remove `ruby` and `ruby-dev` from the apt package list:

```diff
 	sudo apt-get -y install \
 		build-essential \
 		lm-sensors \
 		neofetch \
 		resilio-sync \
-		ruby \
-		ruby-dev \
 		snapd \
 		tmux \
 		unzip \
 		vim-gui-common \
 		vim-runtime \
 		xclip \
 		zsh
```

Also update the "Next steps" block in `install.sh` to point at the new
library location:

```diff
 	echo "Optional:"
-	echo "  - Run $DOTFILES/install/software.sh for VS Code, asdf, Crystal."
+	echo "  - Browse optional tools in $DOTFILES/extras/ (asdf, crystal,"
+	echo "    docker, fly, kvm, python, ruby, rust, vscode)."
```

### Update `CLAUDE.md`

The paragraph about `install/software.sh` needs to point at `extras/`:

```diff
-`install/software.sh` is a separate, manually-run script for optional tools (VS Code, asdf, Crystal) — not called from `install.sh`. Invoke directly when you want those tools.
+Optional tools live in `extras/` (asdf, crystal, docker, fly, kvm, python, ruby, rust, vscode). Each is a self-contained, idempotent install script. Run `./extras/<tool>` to install one; `extras/README.md` lists what's available. Not called from `install.sh`.
```

## Validation

1. `ls extras/` lists all 10 entries (9 scripts + README.md).
2. All 9 scripts are executable (`-rwxr-xr-x`).
3. `bash -n extras/<script>` passes for each.
4. `extras/README.md` table is in sync with the actual filenames in the
   directory.
5. `install/software.sh` no longer exists.
6. `install.sh`'s apt list no longer contains `ruby` or `ruby-dev`.
7. Smoke test one tool: `./extras/fly` on a machine where `command -v
   fly` is already true — should early-exit with the "already installed"
   message, not download anything. (If fly isn't yet installed, running
   it will download and install — acceptable for a live test.)

## Out of scope

- A wrapper command to list or pick from the library (can be added later
  if the library grows enough to need one).
- Uninstall scripts (removing a tool is case-by-case; YAGNI until needed).
- Inter-script dependencies beyond the asdf bootstrap pattern.
- Testing `extras/kvm` end-to-end (requires hardware virt + logout — out
  of scope for an automated run).
- Installing any tool automatically during `install.sh` — the whole
  point of `extras/` is that they're opt-in.
- macOS versions of `extras/kvm` (UTM is mentioned in the script's
  output; a dedicated `extras/utm` script can be added later).
