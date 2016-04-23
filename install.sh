#!/usr/bin/env bash
DOTFILES=$HOME/.dotfiles

echo -e "Installing dotfiles\n"

echo "Initializing submodule(s)"
git -C $DOTFILES submodule update --init --recursive

source $DOTFILES/install/link.sh

if [ "$(uname -s)" == "Darwin" ]; then
	echo -e "\n\nRunning on OSX"

	source $DOTFILES/install/brew.sh

	source $DOTFILES/install/osx.sh

	source $DOTFILES/install/nvm.sh

elif [ "$(uname -s)" == "Linux" ]; then
	echo -e "\n\nRunning on Linux"

	sudo apt-get update
	sudo apt-get intall ruby
	sudo apt-get install ruby-dev
	sudo apt-get install conky conky-all
	sudo apt-get install zsh

	# TODO: install npm
	npm install -g bower

	echo "Disabling Caps Lock in favor of CTRL"
	setxkbmap -option ctrl:nocaps

else
	echo -e "\n\nOnly Linux and OSX are supported."
fi

echo "Creating vim directories"
mkdir -p ~/.vim-tmp

echo "Creating bin directories"
mkdir -p ~/bin

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
