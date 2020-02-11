#!/usr/bin/env bash

echo "Installing Keybase"
curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
sudo apt install ./keybase_amd64.deb
rm keybase_amd64.deb
run_keybase

echo "Installing Atom"
curl https://atom.io/download/deb -o atom_amd64.deb
sudo apt install ./atom_amd64.deb
rm atom-amd64.deb

echo "Installing Visual Studio Code"
# This link will need to be updated from time to time
curl https://go.microsoft.com/fwlink/?LinkID=760868 -o code_amd64.deb
sudo apt install ./code_amd64.deb
rm code_amd64.deb
