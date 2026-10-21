#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
DATA_ROOT=${XDG_DATA_HOME:-$HOME/.local/share}

[[ -d "$DATA_ROOT/nvim/lazy" ]] || {
    printf 'Missing lazy.nvim data directory: %s\n' "$DATA_ROOT/nvim/lazy" >&2
    exit 1
}
if [[ -e "$DATA_ROOT/nvim/site/pack/packer" || -L "$DATA_ROOT/nvim/site/pack/packer" ]]; then
    printf 'Refusing to archive legacy Packer packages. Run setup_init_file.sh first.\n' >&2
    exit 1
fi

# Replace the previous archive only after tar finishes successfully.
staging_archive=$(mktemp "$PROJECT_ROOT/.nvim.tar.xz.XXXXXX")
trap 'rm -f -- "$staging_archive"' EXIT
tar -Jcf "$staging_archive" -C "$DATA_ROOT" nvim
mv -- "$staging_archive" "$PROJECT_ROOT/nvim.tar.xz"
printf 'Updated %s\n' "$PROJECT_ROOT/nvim.tar.xz"
