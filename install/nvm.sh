#!/bin/sh

echo -e "\n\nInstall NVM"
git clone https://github.com/nvm-sh/nvm.git ~/.nvm
cd ~/.nvm
git checkout v0.39.0
. ./nvm.sh
cd -