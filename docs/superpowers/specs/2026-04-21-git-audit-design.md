# git-audit and git-grab rename — design

Add a sync-status audit tool for repos under `~/git`, and rename the existing
`gitme` cloning helper to match the `git-*` naming so both work as git
subcommands.

## Context

`~/git` is the user's development workspace. Current layout mixes direct repos
(`~/git/flutter`, `~/git/zoom`) with organization folders containing nested
repos (`~/git/neutrinographics/foo`, `~/git/unfoldingWord/bar`).

Existing scripts in `bin/`:
- `bin/gitme` — bash, 23 lines. Clones `user/repo` from GitHub into `~/git/`.

No tool currently answers "do I have uncommitted or unpushed work anywhere
in `~/git`?" — that's what `git-audit` is for. Before this change, answering
that question required `find ~/git -name .git -type d -prune` plus per-repo
`git status` calls by hand.

## Decisions

1. **Rename `bin/gitme` → `bin/git-grab`.** Hyphenated `git-*` names let git
   treat them as subcommands (`git grab user/repo`). Pure rename — no
   behavior change inside the script.
2. **New `bin/git-audit`.** Bash, matches the style of `gitme`/`git-grab`.
   Read-only: never runs anything that mutates a repo.
3. **Report only unsynced repos.** Clean repos produce no output. This makes
   the tool useful as a fast eyeball scan before putting the laptop away.
4. **Default offline; `--fetch` opts in to network.** Fetching can be slow on
   many repos, so the default is fast and based on locally-cached remote refs.
5. **Manual test plan, not a test harness.** Matches the repo norm
   (`CLAUDE.md`: "There are no package.json, Makefile, or test suite").

## Changes

### `bin/gitme` → `bin/git-grab` — rename

Behavior unchanged. The two user-visible strings inside the script don't
mention the command name by name, so nothing inside the script needs to
change.

One outside reference: `CLAUDE.md:56` calls out `gitme` as the notable
script in `bin/`. Update that line to say `git-grab` instead.

No other callers in the repo reference `gitme` (verified by grep across all
files except the design docs themselves). No alias or shim is needed.

### `bin/git-audit` — new

#### Usage

```
git-audit [path]
git audit [path]           # via git's subcommand dispatch
git-audit --fetch
git-audit -v ~/some/dir
```

- `path` — optional, defaults to `~/git`. Must exist or exit 2.
- `--fetch` — run `git fetch --quiet --all` on each repo first, bounded to
  8 concurrent fetches via `xargs -P 8` or equivalent. Does no other network
  I/O. Omitted by default.
- `-v` / `--verbose` — multi-line per-repo output instead of compact.
- `-h` / `--help` — usage and exit 0.

#### Discovery

Recursively walk `path`. Any directory containing a `.git` entry (directory
or file — gitfile worktrees count) is a repo. Stop descending into any
directory identified as a repo; nested submodules and vendored checkouts are
not separately audited.

Unreadable directories (permission denied) are reported as `[unreadable]`
and skipped, not fatal.

Implementation sketch: walk directories and, for each, test whether
`$dir/.git` exists (as either a directory or a gitfile); when it does,
record `$dir` as a repo and skip descending into it. A `find` form that
handles both shapes:

```bash
find "$path" -type d \
  \( -execdir test -e {}/.git \; -print -prune \) \
  -o -type d
```

The implementer is free to use a bash-level walker instead if it reads
more clearly; the discovery semantics are what matter.

#### Per-repo checks

For each repo, compute the following conditions. A repo is flagged if any
apply.

| Tag                   | Condition                                                                  | How computed                                                                |
| --------------------- | -------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `uncommitted`         | Modified or deleted tracked files in the working tree                      | `git status --porcelain` lines starting with ` M`, ` D`, `MM`, `AM`, etc.   |
| `staged`              | Staged changes not yet committed                                           | `git status --porcelain` lines with staged (first-column) status            |
| `untracked`           | Untracked files not covered by `.gitignore`                                | `git status --porcelain` lines starting with `??`                           |
| `unpushed:N`          | Current branch has N commits ahead of its upstream                         | `git rev-list --count @{u}..HEAD`, only if upstream exists and HEAD is on a branch |
| `no-upstream:<branch>` | Current branch is not tracking any remote branch                           | `git rev-parse --abbrev-ref --symbolic-full-name @{u}` returns non-zero     |
| `no-remote`           | Repo has no remotes configured at all                                      | `git remote` produces empty output                                          |
| `unreadable`          | Directory not readable due to permissions                                  | Detected during discovery                                                   |
| `error: <msg>`        | A git command failed inside a readable repo (e.g. corrupted `.git`)         | Non-zero exit from any of the above commands                                |

Only the **current branch** is checked for unpushed/no-upstream. Other local
branches are not audited — tracking every local branch adds scope and noise
(stale feature branches are a common, intentional state). If the user later
wants that, it's a straightforward extension.

Detached HEAD is treated as a valid state:
- `uncommitted` / `staged` / `untracked` are still checked.
- `unpushed` / `no-upstream` are skipped (nothing meaningful to compare
  against). Detached HEAD by itself is not flagged.

#### Output format

Paths are displayed relative to the input `path` argument, so the report
reads cleanly regardless of how deeply nested repos are.

**Compact (default):**

```
neutrinographics/foo       [uncommitted] [unpushed:2]
unfoldingWord/bar          [untracked] [no-upstream:feature-x]
zoom                       [no-remote]
corrupted-thing            [error: fatal: not a git repository]
secret-dir                 [unreadable]
```

Two-column layout. Tag order follows the table above (working-tree tags
before branch tags). Tags are fixed strings. Colors only when stdout is
a TTY (`[[ -t 1 ]]`): red for the tag names, default for the path and
brackets. Piping the output stays plain.

**Verbose (`-v`):**

```
neutrinographics/foo
  Modified:    src/main.rs, README.md
  Untracked:   notes.txt
  Unpushed:    main (2 commits ahead of origin/main)
unfoldingWord/bar
  Untracked:   TODO.md
  No upstream: feature-x
```

File/branch lists truncate to 5 entries and append ` (+N more)` beyond.
Ordering inside each category follows `git status --porcelain` order
(git's own stable ordering).

#### Exit code

- `0` — no flagged repos.
- `1` — at least one repo was flagged (includes `unreadable` and `error`).
- `2` — usage error: invalid flag, non-existent path.

This matches standard Unix "grep-style" exit semantics and makes the tool
composable in shell: `git-audit && echo "all clean"`.

#### Shell safety

- `set -u` and `set -o pipefail` on at the top of the script.
- `set -e` **off** — per-repo git failures are expected and handled
  individually via explicit exit-status checks.
- Quote all path expansions; never use unquoted `$path`.
- `find … -print0 | while IFS= read -r -d '' repo; do …` for handling paths
  with spaces or newlines.

## Validation

Manual test plan. Build a fixture and run the tool against it.

All `git init` calls use `-b main` so results don't depend on the user's
git version or `init.defaultBranch` config. Every repo that needs a remote
gets its own local bare (so pushes don't collide with each other and no
network is involved). Bare repos are named `_*.bare` so they're trivially
distinguishable from audit targets in listings; they have no `.git`
subdirectory, so the auditor's discovery won't flag them.

Each fixture is isolated to produce exactly the tag(s) being tested.

```bash
fixture=$(mktemp -d) && cd "$fixture"

# Helper: create repo $1 with its own bare remote; main is pushed and
# tracking origin/main. After this, the repo is in a "clean, synced" state.
synced() {
  local n="$1"
  local bare="$fixture/_${n//\//-}.bare"
  git init --bare -b main "$bare" >/dev/null
  mkdir -p "$(dirname "$n")"
  git init -b main "$n" >/dev/null
  ( cd "$n" \
    && git commit --allow-empty -m init \
    && git remote add origin "$bare" \
    && git push -u origin main >/dev/null 2>&1 )
}

# clean — should NOT appear
synced clean

# uncommitted
synced dirty
( cd dirty && echo x > a && git add a && git commit -m add-a \
  && git push >/dev/null 2>&1 && echo changed >> a )

# staged
synced staged
( cd staged && echo x > a && git add a )

# untracked
synced untracked
( cd untracked && echo x > new.txt )

# unpushed — two local-only commits on top of the synced state
synced unpushed
( cd unpushed \
  && git commit --allow-empty -m second \
  && git commit --allow-empty -m third )

# no-upstream — repo has a remote and main tracks it, but current branch
# feature-x is local-only
synced nou
( cd nou && git checkout -b feature-x )

# no-remote — no remote configured at all
git init -b main no-remote >/dev/null
( cd no-remote && git commit --allow-empty -m init )

# detached HEAD, clean — should NOT appear
synced detached
( cd detached && git commit --allow-empty -m second \
  && git push >/dev/null 2>&1 && git checkout HEAD~1 2>/dev/null )

# org-folder nesting: clean repo inside a subdir, should NOT appear
synced org/inner

# unreadable
mkdir unreadable
( cd unreadable && git init -b main . >/dev/null \
  && git commit --allow-empty -m init )
chmod 000 unreadable/.git

git-audit "$fixture"
```

Expected report (order is filesystem-dependent; tag content is what matters):

- `dirty` → `[uncommitted]`
- `staged` → `[staged]`
- `untracked` → `[untracked]`
- `unpushed` → `[unpushed:2]`
- `nou` → `[no-upstream:feature-x]`
- `no-remote` → `[no-remote]`
- `unreadable` → `[unreadable]` (or `[error: ...]`, depending on where the
  permission failure surfaces)

Absent from the report: `clean`, `detached`, `org/inner`.

Exit code: `1`.

Verbose check: rerun with `-v`; each flagged repo shows the multi-line
detail block described in the Output section.

Fetch check: `git-audit --fetch "$fixture"` — all remotes are local bares,
so fetches succeed without network; the report is identical to the
non-fetch run.

Cleanup: `chmod -R 755 "$fixture"; rm -rf "$fixture"`.

## Out of scope

- Auditing local branches other than the current one. Stale feature
  branches are common and intentional.
- Checking for stashes — intentional local state, not "unsafe."
- Checking whether the current branch is *behind* its remote — being out
  of date isn't unsafe, just stale.
- Submodule auditing — discovery stops at the outermost repo.
- A configurable default base path (the `[path]` arg covers this).
- Parallel execution of the per-repo checks themselves. Only `--fetch`
  parallelizes, because fetch is the only network-bound step.
- A test harness or CI — the repo doesn't have one and this isn't the
  place to introduce it.
- Changes to `gitme`'s behavior. This rename is rename-only.
