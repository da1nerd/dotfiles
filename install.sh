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

	# i3 stuff
	# TODO: instead of overwriting the theme list we should just insert if it 
	# does not exist
	# sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/Horst3180/xUbuntu_15.10/ /' > /etc/apt/sources.list.d/arc-theme.list"
	# sudo add-apt-repository -y ppa:moka/stable

	sudo apt-get update
	sudo apt-get -y install ruby
	sudo apt-get -y install ruby-dev
	#sudo apt-get -y install conky conky-all
	sudo apt-get -y install zsh
	sudo apt-get -y install lm-sensors
	sudo apt-get -y install xclip
	sudo apt-get -y install tmux
	sudo apt-get -y install vim-gui-common
	sudo apt-get -y install vim-runtime
	sudo apt-get -y install build-essential
	sudo apt-get -y install php7.0 php7.0-fpm php7.0-mysql php7.0-mbstring
	sudo apt-get -y install nginx
	curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
	sudo apt-get -y install nodejs

	# yarn for package management
	sudo apt-get update && sudo apt-get install yarn	

	# i3 stuff
	#sudo apt-get -y install i3
	#sudo apt-get -y install feh
	#sudo apt-get -y install arandr
	#sudo apt-get -y install lxappearance
	#sudo apt-get -y install thunar
	#sudo apt-get -y install arc-theme
	#sudo apt-get -y install moka-icon-theme
	#sudo apt-get -y install rofi
	#sudo apt-get -y install compton
	#sudo apt-get -y install i3blocks
	#sudo apt-get -y install pavucontrol
	#sudo apt-get -y install scrot
	#sudo apt-get -y install imagemagick

	#npm install -g bower
	sudo apt-get -y autoremove

	npm i -g git-stats
	npm i -g git-stats-importer

	echo "You need to change the nginx user for vhosts to work"
	echo "edit /etc/nginx/nginx.conf"
	echo ""
	echo "You need to change the php7.0 user and group to your username"
	echo "edit /etc/php/7.0/fpm/pool.d/www.conf"

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
echo "Finish with 'vim +PlugInstall' to set up vim"
