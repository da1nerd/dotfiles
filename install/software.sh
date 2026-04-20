#!/usr/bin/env bash

if ! command -v code >/dev/null 2>&1; then
	echo "Installing Visual Studio Code"
	curl -L "https://go.microsoft.com/fwlink/?LinkID=760868" -o /tmp/code_amd64.deb
	sudo apt install -y /tmp/code_amd64.deb
	rm /tmp/code_amd64.deb
fi

if [ ! -d ~/.asdf ]; then
	echo "Installing asdf"
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf
	(cd ~/.asdf && git checkout "$(git describe --abbrev=0 --tags)")
fi

. ~/.asdf/asdf.sh

if ! asdf plugin list 2>/dev/null | grep -qx crystal; then
	echo "Adding asdf crystal plugin"
	asdf plugin add crystal
fi

echo "Installing latest crystal"
asdf install crystal latest

# TODO: also install: typora, brave
