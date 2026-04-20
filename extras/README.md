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
| `claude`  | Claude Code CLI + superpowers plugin declaration      |
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
