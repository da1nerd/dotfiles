#!/usr/bin/env bash

DOTFILES=$HOME/.dotfiles

echo -e "\nCreating symlinks"
echo "=============================="
linkables=$( find -H "$DOTFILES" -maxdepth 3 -name '*.symlink' )
for file in $linkables ; do
    target="$HOME/.$( basename $file '.symlink' )"
    if [ -e $target ]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $file"
        ln -s $file $target
    fi
done

echo -e "\n\nInstalling to ~/.config"
echo "=============================="
if [ ! -d $HOME/.config ]; then
    echo "Creating ~/.config"
    mkdir -p $HOME/.config
fi
#configs=$( find -maxdepth 1 -path "$DOTFILES/config.symlink")
for config in $DOTFILES/.config/*; do
    target=$HOME/.config/$( basename $config )
    echo "$target"
    if [[ -e $target ]]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $config"
        ln -s $config $target
    fi
done

# TODO: load conky paths into an array and iterate
#if [[ $(uname) == 'Linux' ]]; then
#    echo -e "\n\nCreating conky symlinks"
    #echo "=============================="
    #if [[ ! -e ~/.conky ]]; then
    #    ln -s $DOTFILES/conky ~/.conky
    #else
    #    echo "~/.conky already exists... Skipping."
    #fi
    #if [[ ! -e ~/.conkyrc ]]; then
    #    ln -s $DOTFILES/conky/conkyrc ~/.conkyrc
    #else
    #    echo "~/.conkyrc already exists... Skipping."
    #fi
#fi

