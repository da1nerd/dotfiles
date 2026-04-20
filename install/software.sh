#!/usr/bin/env bash

echo "Installing Visual Studio Code"
# This link will need to be updated from time to time
curl -L https://go.microsoft.com/fwlink/?LinkID=760868 -o code_amd64.deb
sudo apt install ./code_amd64.deb
rm code_amd64.deb

echo "Installing asdf"
git clone https://github.com/asdf-vm/asdf.git ~/.asdf
cd ~/.asdf
git checkout "$(git describe --abbrev=0 --tags)"

echo "Installing Crystal-lang"
asdf plugin add crystal
asdf install crystal latest

# TODO: also install: typora, brave
