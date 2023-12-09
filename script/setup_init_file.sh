#!/bin/bash
SETUP_DIR=$HOME/.local/share
INIT_DIR=$HOME/.config/nvim
PROJECT_ROOT=$(pwd)

if [ -d $INIT_DIR ] ;then
    rm -rf $INIT_DIR
fi

ln -s $PROJECT_ROOT/nvim $INIT_DIR
