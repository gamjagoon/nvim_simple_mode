#!/bin/bash

if [ ! -f "~/.local/share" ] ;then
    mkdir -p ~/.local/share
fi
cp nvim.tar.xz  ~/.local/share/
cd ~/.local/share
tar -Jxf nvim.tar.xz
