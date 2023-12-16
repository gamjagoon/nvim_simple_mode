#!/bin/bash
SETUP_DIR=$HOME/.local/share
INIT_DIR=$HOME/.config/nvim
PACKER_DIR=$HOME/.local/share/nvim/site/pack/packer/start
PROJECT_ROOT=$(pwd)

if [ ! -d $HOME/.config ] ;then
	mkdir $HOME/.config
fi

if [ ! -d $PACKER_DIR ] ;then
	mkdir -p $PACKER_DIR
else
	if [ -d $SETUP_DIR/nvim ] ;then
    	rm -rf $SETUP_DIR/nvim
	fi
fi

if [ -d $INIT_DIR ] ;then
    rm -rf $INIT_DIR
fi

ln -s $PROJECT_ROOT/nvim $INIT_DIR
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
