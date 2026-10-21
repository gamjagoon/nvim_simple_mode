#!/usr/bin/env bash
set -euo pipefail

if [[ ${NVIM_APPNAME:-nvim} != nvim ]]; then
    printf 'Unset NVIM_APPNAME before installing this nvim configuration.\n' >&2
    exit 1
fi

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
INIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
DATA_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/nvim

backup() {
    local source=$1
    local destination
    destination="${source}.backup.$(date +%Y%m%d-%H%M%S).$$"
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

# Moving a parent of this checkout would invalidate the source before linking it.
for target in "$INIT_DIR" "$DATA_DIR"; do
    [[ -d "$target" ]] || continue
    if [[ "$target" != "$INIT_DIR" && ! -e "$DATA_DIR/site/pack/packer" && ! -L "$DATA_DIR/site/pack/packer" ]]; then
        continue
    fi
    physical_target=$(cd -- "$target" && pwd -P)
    case "$PROJECT_ROOT/" in
        "$physical_target/"*)
            printf 'Repository is inside installation/backup target %s; move the checkout first.\n' "$target" >&2
            exit 1
            ;;
    esac
done

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
