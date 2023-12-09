#!/bin/bash
SEDUP_DIR=$HOME/.local/share
PROJECT_ROOT=$(pwd)

if [ ! -d "$SEDUP_DIR/nvim" ] ;then
    echo "nvim folder not eixst"
else 
    rm nvim.tar.xz
    cd $SEDUP_DIR
    tar -Jcf nvim.tar.xz nvim
    mv nvim.tar.xz $PROJECT_ROOT
    cd $PROJECT_ROOT
fi
