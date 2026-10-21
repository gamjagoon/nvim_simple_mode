#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT
FIXTURE=$TEST_ROOT/project\ with\ spaces
mkdir -p "$FIXTURE/script" "$FIXTURE/nvim"
cp "$PROJECT_ROOT"/script/*.sh "$FIXTURE/script/"
printf '%s\n' '-- test configuration' > "$FIXTURE/nvim/init.lua"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
run_script() {
    env HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/config root" \
        XDG_DATA_HOME="$TEST_ROOT/data root" bash "$FIXTURE/script/$1"
}
config=$TEST_ROOT/config\ root/nvim
data=$TEST_ROOT/data\ root/nvim

# Run from a different directory; preserve directories and legacy Packer data.
cd "$TEST_ROOT"
mkdir -p "$config" "$data/site/pack/packer/start/plugin"
printf 'old config\n' > "$config/old.lua"
printf 'old plugin\n' > "$data/site/pack/packer/start/plugin/sentinel"
run_script setup_init_file.sh
[[ -L "$config" && "$config" -ef "$FIXTURE/nvim" ]] || fail 'configuration link'
config_backups=("$config".backup.*)
data_backups=("$data".backup.*)
[[ $(cat "${config_backups[0]}/old.lua") == 'old config' ]] || fail 'configuration backup'
[[ -f "${data_backups[0]}/site/pack/packer/start/plugin/sentinel" ]] || fail 'Packer backup'

# Reinstalling retains lazy data and makes no additional configuration backup.
mkdir -p "$data/lazy/plugin"
printf 'installed plugin\n' > "$data/lazy/plugin/sentinel"
run_script setup_init_file.sh
new_backups=("$config".backup.*)
[[ ${#new_backups[@]} == 1 && -f "$data/lazy/plugin/sentinel" ]] || fail 'idempotent installation'

# Existing dangling links and regular files must also survive as backups.
rm "$config"
ln -s "$TEST_ROOT/missing-target" "$config"
run_script setup_init_file.sh
found_link=false
for candidate in "$config".backup.*; do
    if [[ -L "$candidate" && $(readlink "$candidate") == "$TEST_ROOT/missing-target" ]]; then
        found_link=true
    fi
done
[[ "$found_link" == true ]] || fail 'dangling symlink backup'
rm "$config"
printf 'old file\n' > "$config"
run_script setup_init_file.sh
found_file=false
for candidate in "$config".backup.*; do
    if [[ -f "$candidate" && $(cat "$candidate") == 'old file' ]]; then found_file=true; fi
done
[[ "$found_file" == true ]] || fail 'regular file backup'

# Snapshot and restore use XDG paths, and preserve installed data first.
run_script update_nvim_dump.sh
printf 'current data\n' > "$data/current"
run_script setup_nvim_dump.sh
[[ -f "$data/lazy/plugin/sentinel" && ! -e "$data/current" ]] || fail 'dump restoration'
found_current=false
for candidate in "$data".backup.*; do
    if [[ -f "$candidate/current" ]]; then found_current=true; fi
done
[[ "$found_current" == true ]] || fail 'restore data backup'

# Refuse an old Packer dump before altering current data.
mkdir -p "$TEST_ROOT/legacy/nvim/site/pack/packer/start/plugin"
tar -Jcf "$FIXTURE/nvim.tar.xz" -C "$TEST_ROOT/legacy" nvim
if run_script setup_nvim_dump.sh; then fail 'accepted legacy Packer dump'; fi
[[ -f "$data/lazy/plugin/sentinel" ]] || fail 'legacy rejection changed data'

# A failed archive update must leave the previous archive byte-for-byte intact.
cp "$FIXTURE/nvim.tar.xz" "$TEST_ROOT/previous.tar.xz"
mkdir -p "$TEST_ROOT/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_ROOT/bin/tar"
chmod +x "$TEST_ROOT/bin/tar"
if PATH="$TEST_ROOT/bin:$PATH" run_script update_nvim_dump.sh; then fail 'tar failure ignored'; fi
cmp "$FIXTURE/nvim.tar.xz" "$TEST_ROOT/previous.tar.xz" || fail 'failed update replaced archive'

# Defaults also work without XDG environment variables.
env -u XDG_CONFIG_HOME -u XDG_DATA_HOME HOME="$TEST_ROOT/default-home" \
    bash "$FIXTURE/script/setup_init_file.sh"
[[ "$TEST_ROOT/default-home/.config/nvim" -ef "$FIXTURE/nvim" ]] || fail 'default HOME installation'
printf 'PASS: installation backups, idempotency, XDG/default paths, dump restore and failure preservation\n'
