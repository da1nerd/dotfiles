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

	echo "deb http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list
	curl -LO http://linux-packages.resilio.com/resilio-sync/key.asc && sudo apt-key add ./key.asc

	sudo apt-get update
	sudo apt-get -y install ruby
	sudo apt-get -y install neofetch
	sudo apt-get -y install ruby-dev
	sudo apt-get -y install zsh
	sudo apt-get -y install lm-sensors
	sudo apt-get -y install xclip
	sudo apt-get -y install tmux
	sudo apt-get -y install vim-gui-common
	sudo apt-get -y install vim-runtime
	sudo apt-get -y install build-essential
	sudo apt-get -y install resilio-sync
	sudo apt-get -y install snapd
	sudo apt-get -y autoremove

	# Configure sync
	sudo systemctl enable resilio-sync
	sudo usermod -aG $USER rslsync
	sudo usermod -aG rslsync $USER
	sudo service resilio-sync start

	echo "Installing Node Version Manager (nvm)"
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | zsh

	echo "Creating vim directories"
	mkdir -p ~/.vim-tmp
else
	echo -e "\n\nOnly Linux and OSX are supported."
fi

echo "Creating bin directories"
mkdir -p ~/bin

echo "Configuring zsh as default shell"
chsh -s $(which zsh)
touch ~/.zshrc
echo "# Automatically added by dotfiles" >> ~/.zshrc
echo "source $DOTFILES/zsh/zshrc.bootstrap" >> ~/.zshrc

echo "Installing the latest version of node for you"
nvm install stable
nvm alias default stable

echo "Done."
echo "Finish with 'vim +PlugInstall' to set up vim"
echo "You may need to log out in order for all changes to take effect."

# Display some fun system information
if [ "$(uname -s)" == "Linux" ]; then
	echo "You can install additional software by running $DOTFILES/install/software.sh"
	neofetch
fi
