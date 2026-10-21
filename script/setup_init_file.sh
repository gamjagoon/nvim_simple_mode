#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
INIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
DATA_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/nvim

backup() {
    local source=$1
    local destination="${source}.backup.$(date +%Y%m%d-%H%M%S).$$"
    while [[ -e "$destination" || -L "$destination" ]]; do
        destination="${destination}.1"
    done
    mv -- "$source" "$destination"
    printf 'Backed up %s to %s\n' "$source" "$destination"
}

[[ -f "$PROJECT_ROOT/nvim/init.lua" ]] || {
    printf 'Missing Neovim configuration: %s\n' "$PROJECT_ROOT/nvim/init.lua" >&2
    exit 1
}

# Old native packages can load alongside lazy.nvim plugins. Preserve them outside
# Neovim's data path; retain an existing lazy.nvim installation on repeat runs.
if [[ -e "$DATA_DIR/site/pack/packer" || -L "$DATA_DIR/site/pack/packer" ]]; then
    backup "$DATA_DIR"
fi

if [[ -L "$INIT_DIR" && "$INIT_DIR" -ef "$PROJECT_ROOT/nvim" ]]; then
    printf 'Configuration already linked: %s\n' "$INIT_DIR"
    exit 0
fi

mkdir -p -- "$(dirname -- "$INIT_DIR")"
if [[ -e "$INIT_DIR" || -L "$INIT_DIR" ]]; then
    backup "$INIT_DIR"
fi
ln -s -- "$PROJECT_ROOT/nvim" "$INIT_DIR"
printf 'Linked %s to %s\n' "$INIT_DIR" "$PROJECT_ROOT/nvim"
