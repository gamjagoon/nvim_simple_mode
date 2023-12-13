#!/bin/bash
SETUP_DIR=$HOME/.local/share
INIT_DIR=$HOME/.config/nvim
PROJECT_ROOT=$(pwd)

if [ ! -d $HOME/.config ] ;then
	mkdir $HOME/.config
fi

if [ -d $INIT_DIR ] ;then
    rm -rf $INIT_DIR
fi

ln -s $PROJECT_ROOT/nvim $INIT_DIR
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
