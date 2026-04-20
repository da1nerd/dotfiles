#!/usr/bin/env bash
DOTFILES=$HOME/.dotfiles
NVM_VERSION=v0.40.1

echo -e "Installing dotfiles\n"

echo "Initializing submodule(s)"
git -C $DOTFILES submodule update --init --recursive

source $DOTFILES/install/link.sh

if [ "$(uname -s)" == "Darwin" ]; then
	echo -e "\n\nRunning on OSX"

	source $DOTFILES/install/brew.sh

	source $DOTFILES/install/osx.sh

elif [ "$(uname -s)" == "Linux" ]; then
	echo -e "\n\nRunning on Linux"

	# resilio-sync apt repository (idempotent)
	if [ ! -f /etc/apt/keyrings/resilio-sync.gpg ]; then
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL http://linux-packages.resilio.com/resilio-sync/key.asc \
			| sudo gpg --dearmor -o /etc/apt/keyrings/resilio-sync.gpg
	fi
	if [ ! -f /etc/apt/sources.list.d/resilio-sync.list ]; then
		echo "deb [signed-by=/etc/apt/keyrings/resilio-sync.gpg] http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" \
			| sudo tee /etc/apt/sources.list.d/resilio-sync.list
	fi

	sudo apt-get update
	sudo apt-get -y install \
		build-essential \
		lm-sensors \
		neofetch \
		resilio-sync \
		ruby \
		ruby-dev \
		snapd \
		tmux \
		vim-gui-common \
		vim-runtime \
		xclip \
		zsh
	sudo apt-get -y autoremove

	# Configure resilio sync
	sudo systemctl enable resilio-sync
	sudo usermod -aG $USER rslsync
	sudo usermod -aG rslsync $USER
	sudo service resilio-sync start

	echo "Creating vim directories"
	mkdir -p ~/.vim-tmp
else
	echo -e "\n\nOnly Linux and OSX are supported."
fi

# Install nvm via git clone (idempotent; shared between macOS and Linux)
if [ ! -d ~/.nvm ]; then
	echo "Installing Node Version Manager (nvm) $NVM_VERSION"
	git clone https://github.com/nvm-sh/nvm.git ~/.nvm
	(cd ~/.nvm && git checkout "$NVM_VERSION")
fi

echo "Creating bin directories"
mkdir -p ~/bin

if [ "$(basename "$SHELL")" != "zsh" ]; then
	echo "Configuring zsh as default shell"
	chsh -s "$(which zsh)"
fi

touch ~/.zshrc
if ! grep -qF "source $DOTFILES/zsh/zshrc.bootstrap" ~/.zshrc; then
	echo "# Automatically added by dotfiles" >> ~/.zshrc
	echo "source $DOTFILES/zsh/zshrc.bootstrap" >> ~/.zshrc
fi

echo "Installing the latest version of node"
. ~/.nvm/nvm.sh
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
