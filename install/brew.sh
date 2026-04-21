#!/bin/sh

if ! command -v brew >/dev/null 2>&1; then
    echo "Installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v wget >/dev/null 2>&1; then
    brew install wget
fi

if ! command -v git >/dev/null 2>&1; then
    brew install git
fi

if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
fi

if ! command -v ack >/dev/null 2>&1; then
    brew install ack
fi

if ! command -v starship >/dev/null 2>&1; then
    brew install starship
fi

if ! brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    brew install --cask font-jetbrains-mono-nerd-font
fi
