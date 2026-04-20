#!/usr/bin/env bash
DOTFILES=$HOME/.dotfiles
NVM_VERSION=v0.40.1

# Preflight: ensure git and curl are present. Needed for submodule init,
# resilio GPG key fetch, starship + nerd-font downloads, and the nvm /
# antidote clones. Safety net in case the user skipped the README prereqs.
missing=()
command -v git >/dev/null || missing+=(git)
command -v curl >/dev/null || missing+=(curl)
if [ ${#missing[@]} -gt 0 ]; then
	echo "Installing missing prereqs: ${missing[*]}"
	if [ "$(uname -s)" == "Linux" ] && command -v apt-get >/dev/null; then
		sudo apt-get update
		sudo apt-get -y install "${missing[@]}"
	elif [ "$(uname -s)" == "Darwin" ]; then
		echo "On macOS, run 'xcode-select --install' for git, then re-run this script."
		exit 1
	else
		echo "Install them manually, then re-run."
		exit 1
	fi
fi

echo -e "Installing dotfiles\n"

echo "Initializing submodule(s)"
if [ -d "$DOTFILES/.git" ]; then
	git -C "$DOTFILES" submodule update --init --recursive
elif [ ! -d "$DOTFILES/.config/base16-shell/scripts" ]; then
	echo "(Not a git checkout — cloning base16-shell manually)"
	rm -rf "$DOTFILES/.config/base16-shell"
	git clone --depth 1 https://github.com/chriskempson/base16-shell.git \
		"$DOTFILES/.config/base16-shell"
fi

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
		snapd \
		tmux \
		unzip \
		vim-gui-common \
		vim-runtime \
		xclip \
		zsh
	sudo apt-get -y autoremove

	# starship prompt (not in Pop!_OS apt)
	if ! command -v starship >/dev/null; then
		curl -sS https://starship.rs/install.sh | sh -s -- --yes
	fi

	# JetBrainsMono Nerd Font (for starship glyphs)
	if [ ! -f ~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf ]; then
		echo "Installing JetBrainsMono Nerd Font"
		mkdir -p ~/.local/share/fonts
		curl -fsSL -o /tmp/JetBrainsMono.zip \
			https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
		unzip -qo /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/
		rm /tmp/JetBrainsMono.zip
		fc-cache -f
	fi

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

# Install antidote plugin manager (idempotent; shared between macOS and Linux)
if [ ! -d ~/.antidote ]; then
	echo "Installing antidote"
	git clone --depth 1 https://github.com/mattmc3/antidote.git ~/.antidote
	# Strip group/other write bits so zsh compinit doesn't flag the
	# functions dir as "insecure" under umasks like Pop!_OS's 002.
	chmod -R go-w ~/.antidote
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

# Display some fun system information (Linux only)
if [ "$(uname -s)" == "Linux" ]; then
	neofetch
fi

echo ""
echo "Dotfiles installation complete."
echo ""
echo "Next steps to finish your setup:"
echo ""
echo "  1. Log out and back in for the zsh shell change to take effect."
echo "  2. Install vim plugins:  vim +PlugInstall"
echo "  3. Set your terminal emulator font to 'JetBrainsMono Nerd Font Mono'"
echo "     (required for starship's git branch / status glyphs to render)."
if [ "$(uname -s)" == "Linux" ]; then
	echo "  4. Configure caps-lock-as-Ctrl via Pop!_OS keyboard settings"
	echo "     (System Settings → Keyboard, or install gnome-tweaks)."
	echo ""
	echo "Optional:"
	echo "  - Browse optional tools in $DOTFILES/extras/ (asdf, crystal,"
	echo "    docker, fly, kvm, python, ruby, rust, vscode)."
fi
echo ""
