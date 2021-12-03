#!/bin/sh

if test ! $(which brew); then
    echo "Installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if test ! $(which wget); then
    brew install wget
fi

if test ! $(which git); then
    brew install git
fi

if test ! $(which zsh); then
    brew install zsh
fi