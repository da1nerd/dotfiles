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

	# set up sources
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

	sudo apt-get update
	sudo apt-get -y install ruby
	sudo apt-get -y install neofetch
	sudo apt-get -y install ruby-dev
	sudo apt-get -y install zsh
	sudo apt-get -y install ack-grep
	sudo apt-get -y install lm-sensors
	sudo apt-get -y install xclip
	sudo apt-get -y install tmux
	sudo apt-get -y install vim-gui-common
	sudo apt-get -y install vim-runtime
	sudo apt-get -y install build-essential
	# sudo apt-get -y install php7.0 php7.0-fpm php7.0-mysql php7.0-mbstring
	# sudo apt-get -y install nginx
	# curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
	sudo apt-get -y install nodejs
	sudo apt-get -y install yarn
	sudo apt-get -y autoremove

	# echo "You need to change the nginx user for vhosts to work"
	# echo "edit /etc/nginx/nginx.conf"
	# echo ""
	# echo "You need to change the php7.0 user and group to your username"
	# echo "edit /etc/php/7.0/fpm/pool.d/www.conf"

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
echo "# Bootstrap zshrc from dotfiles" >> ~/.zshrc
echo "source $DOTFILES/zsh/zshrc.bootstrap" >> ~/.zshrc

echo "Done."
echo "Finish with 'vim +PlugInstall' to set up vim"

# Display some fun system information
neofetch
