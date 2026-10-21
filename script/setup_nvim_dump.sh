#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
DATA_ROOT=${XDG_DATA_HOME:-$HOME/.local/share}
ARCHIVE=$PROJECT_ROOT/nvim.tar.xz

# Validate before touching the installed data. The historical repository archive
# contains Packer packages and must not be mixed with lazy.nvim.
archive_contents=$(tar -tJf "$ARCHIVE")
while IFS= read -r entry; do
    case "$entry" in
        nvim/site/pack/packer|nvim/site/pack/packer/*)
            printf 'Refusing legacy Packer dump. Install plugins with lazy.nvim instead.\n' >&2
            exit 1
            ;;
        /*|../*|*/../*|*/..)
            printf 'Invalid archive path: %s\n' "$entry" >&2
            exit 1
            ;;
        nvim|nvim/*) ;;
        *)
            printf 'Unexpected archive path: %s\n' "$entry" >&2
            exit 1
            ;;
    esac
done <<< "$archive_contents"

mkdir -p -- "$DATA_ROOT"
staging_dir=$(mktemp -d "$DATA_ROOT/.nvim-restore.XXXXXX")
trap 'rm -rf -- "$staging_dir"' EXIT
tar -Jxf "$ARCHIVE" -C "$staging_dir"
[[ -d "$staging_dir/nvim/lazy" ]] || {
    printf 'Archive does not contain a lazy.nvim data directory.\n' >&2
    exit 1
}

if [[ -e "$DATA_ROOT/nvim" || -L "$DATA_ROOT/nvim" ]]; then
    backup_dir="$DATA_ROOT/nvim.backup.$(date +%Y%m%d-%H%M%S).$$"
    while [[ -e "$backup_dir" || -L "$backup_dir" ]]; do
        backup_dir="${backup_dir}.1"
    done
    mv -- "$DATA_ROOT/nvim" "$backup_dir"
    printf 'Backed up data to %s\n' "$backup_dir"
fi
mv -- "$staging_dir/nvim" "$DATA_ROOT/nvim"
printf 'Restored lazy.nvim data to %s\n' "$DATA_ROOT/nvim"
