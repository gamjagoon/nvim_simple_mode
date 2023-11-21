#!/bin/bash

<< COMMENT
	Make config folder
COMMENT
if [ ! -d "$HOME/.config" ]; then
   mkdir $HOME/.config
fi

<< COMMENT
	Copy Setting file
COMMENT
if [ -d "$HOME/.config/nvim" ];then
    if [ -d "$HOME/.config/nvim_bak" ];then
	rm -rf $HOME/.config/nvim_bak
    fi
    mv $HOME/.config/nvim $HOME/.config/nvim_bak
    mkdir $HOME/.config/nvim
    cp init.lua $HOME/.config/nvim/
    cp -r lua $HOME/.config/nvim/
else
    mkdir -p $HOME/.config/nvim
    cp init.lua $HOME/.config/nvim/
    cp -r lua $HOME/.config/nvim/
fi
