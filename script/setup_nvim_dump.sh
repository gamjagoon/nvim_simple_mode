#!/bin/bash
SETUP_DIR=$HOME/.local/share
PROJECT_ROOT=$(pwd)

if [ ! -d $SETUP_DIR ] ;then
    mkdir -p $SETUP_DIR
fi

cp nvim.tar.xz $SETUP_DIR
cd $SETUP_DIR
tar -Jxf nvim.tar.xz
cd $PROJECT_ROOT
