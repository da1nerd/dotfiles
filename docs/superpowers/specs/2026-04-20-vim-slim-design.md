# Vim slim-down — design

Part of the dotfiles repo refinement. Phase 2a of the multi-phase cleanup.
Phases 1 (deletions) and 3 (install-script hardening) are complete.
Phase 2 decomposes into three sub-projects: vim, tmux, zsh. This is vim.

## Context

`vimrc.symlink` is ~330 lines (after phase 1 cleanup): plugins for NERDTree,
CtrlP, airline, syntastic, fugitive, base16; and Vimscript helpers for window
movement, highlight-word, HTML unescape, local-settings walk, etc.

User's actual usage: **barely used — mostly habit**. Real editing happens in
VS Code or Claude Code. Vim is invoked for git commit messages, quick config
edits, and occasional SSH sessions.

Additional observations:

- `zsh/aliases.zsh` has `alias vim="nvim"` but `install.sh` does not install
  neovim. The alias silently falls through to vim. A quiet lie, not a bug.
- `install.sh` installs `vim-gui-common` and `vim-runtime` via apt — actual
  vim is the tool that gets run.
- `vim.symlink/snippets/` contains `.snippets` files, but no snippet plugin
  (ultisnips, vim-snipmate) is declared in the `Plug` block. Dead code.

## Decisions

1. **Simplify, don't modernize.** "Barely used" + ~330-line config is a
   YAGNI violation. Target ~45 lines.
2. **Stay on vim.** Nvim's advantages (LSP, treesitter, Lua, modern plugin
   ecosystem) only pay off for users who live in the editor. For the
   target use case, plain vim is fine and pre-installed.
3. **Keep vim-plug.** Already at `vim.symlink/autoload/plug.vim`. Switching
   to native `pack/*/start/` would require vendoring or submodules for no
   meaningful gain.
4. **Two plugins:** `chriskempson/base16-vim` (matches shell `$THEME`) and
   `tpope/vim-fugitive` (git). Drop everything else.

## Changes

### `vimrc.symlink` — rewrite

```vim
" Minimal vim config — for git commits, quick edits, config tweaks.
" Full IDE work happens in VS Code or Claude Code.

set nocompatible
set nomodeline
set autoread
set backspace=indent,eol,start
set clipboard^=unnamed,unnamedplus

let mapleader = ','

" Undo across sessions
set undofile
set undodir=~/.vim-tmp/undodir

" Indentation (tabs, 4-wide)
set noexpandtab
set smarttab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" UI
set number
set laststatus=2
set showcmd

" Search
set ignorecase
set smartcase
set hlsearch
set incsearch

" jj → ESC
inoremap jj <ESC>

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'chriskempson/base16-vim'
Plug 'tpope/vim-fugitive'
call plug#end()

" Colorscheme (from shell $THEME / $BACKGROUND)
syntax on
let base16colorspace=256
if !empty($BACKGROUND)
    execute "set background=" . $BACKGROUND
endif
if !empty($THEME)
    silent! execute "colorscheme " . $THEME
endif

" Fugitive
nmap <silent> <leader>gs :Git<cr>
nmap <leader>ge :Gedit<cr>
nmap <silent> <leader>gr :Gread<cr>
nmap <silent> <leader>gb :Git blame<cr>
```

Notes on specific choices:

- `silent!` on `colorscheme` so the first-run-before-PlugInstall doesn't
  print an error when `base16-vim` isn't downloaded yet.
- `clipboard^=unnamed,unnamedplus` (prepend, cross-platform) replaces the
  old `clipboard=unnamed`. `unnamedplus` is the X11/Linux system clipboard.
- Plug path changes from `'~/.config/nvim/plugged'` to `'~/.vim/plugged'`
  since we're running vim, not nvim.
- Fugitive mappings use `:Git` / `:Git blame` (modern) instead of
  `:Gstatus` / `:Gblame` (deprecated and removed in recent fugitive).

### `zsh/aliases.zsh` — remove alias

Delete `alias vim="nvim"`. Nvim isn't installed and the alias is a no-op
lie.

### `vim.symlink/snippets/` — delete

No snippet plugin declared; the files are dead. Delete the whole directory
(`gitcommit.snippets`, `html.snippets`, `javascript.snippets`,
`markdown.snippets`, `_.snippets`).

### `vim.symlink/.netrwhist` — untrack

Already in `.gitignore` but was committed previously. `git rm --cached
vim.symlink/.netrwhist` to untrack.

### Unchanged

- `vim.symlink/autoload/plug.vim` — vim-plug bootstrap, still needed
- `ideavimrc.symlink` — separate concern (JetBrains vim bindings)
- `install.sh` — vim is already in the apt package list
- `zshrc.bootstrap` — `export EDITOR='vim'` is already correct

## Validation

1. `vim +PlugInstall +qall` completes without error and downloads
   `base16-vim` and `vim-fugitive` into `~/.vim/plugged/`.
2. Open a file: colorscheme matches the shell theme, `jj` exits insert
   mode, `:Git` opens a fugitive status buffer, `:Git blame` works.
3. `git commit` opens vim (via `$EDITOR`); it opens quickly, no missing
   plugin warnings, quits cleanly.

## Out of scope

- Switching to neovim
- LSP, treesitter, modern plugin ecosystem
- Keybinding redesign beyond renamed fugitive commands
- Snippet system revival
- Changes to `ideavimrc.symlink` or IDE vim bindings
