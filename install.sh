#!/usr/bin/env bash

echo "Installing tools"
apt update
apt intall ruby
apt install ruby-dev
npm install -g bower
apt install conky conky-all

echo "Installing dotfiles"

echo "Initializing submodule(s)"
git submodule update --init --recursive

source install/link.sh

echo "creating vim directories"
mkdir -p ~/.vim-tmp

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Configuring Conky"
ln -s ~/.dotfiles/conky ~/.conky

echo "Disabling Caps Lock in favor of CTRL"
setxkbmap -option ctrl:nocaps

echo "Done."
