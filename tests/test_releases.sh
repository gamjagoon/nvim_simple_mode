#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/assets/nvim-linux-x86_64/bin"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Real archives contain tiny executable fixtures; only HTTP is mocked.
printf '#!/bin/sh\nprintf "NVIM v9.8.7\\n"\n' > "$TEST_ROOT/assets/nvim-linux-x86_64/bin/nvim"
chmod +x "$TEST_ROOT/assets/nvim-linux-x86_64/bin/nvim"
tar -czf "$TEST_ROOT/assets/nvim.tar.gz" -C "$TEST_ROOT/assets" nvim-linux-x86_64
printf '#!/bin/sh\nprintf "tree-sitter 9.7.6\\n"\n' | gzip > "$TEST_ROOT/assets/tree-sitter.gz"
printf '#!/bin/sh\nprintf "tree-sitter 9.7.5\\n"\n' | gzip > "$TEST_ROOT/assets/wrong-tree-sitter.gz"
cat > "$TEST_ROOT/bin/uname" <<'STUB'
#!/usr/bin/env bash
printf 'x86_64\n'
STUB
cat > "$TEST_ROOT/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
output= head=false url=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output) output=$2; shift 2 ;;
        --write-out|--retry) shift 2 ;;
        --head) head=true; shift ;;
        https://*) url=$1; shift ;;
        *) shift ;;
    esac
done
printf '%s\n' "$url" >> "$RELEASE_TEST_LOG"
if "$head"; then
    case "$url" in
        https://github.com/neovim/neovim/releases/latest)
            case "$RELEASE_TEST_MODE" in
                invalid-tag) printf 'https://github.com/neovim/neovim/releases/tag/nightly'; exit ;;
                old-tag) printf 'https://github.com/neovim/neovim/releases/tag/v0.1.0'; exit ;;
            esac
            printf 'https://github.com/neovim/neovim/releases/tag/v9.8.7'
            ;;
        https://github.com/tree-sitter/tree-sitter/releases/latest)
            if [[ "$RELEASE_TEST_MODE" == metadata-failure ]]; then exit 22; fi
            printf 'https://github.com/tree-sitter/tree-sitter/releases/tag/v9.7.6'
            ;;
        *) exit 22 ;;
    esac
else
    case "$url" in
        https://github.com/neovim/neovim/releases/download/v9.8.7/nvim-linux-x86_64.tar.gz)
            cp "$RELEASE_TEST_ASSETS/nvim.tar.gz" "$output" ;;
        https://github.com/tree-sitter/tree-sitter/releases/download/v9.7.6/tree-sitter-linux-x64.gz)
            if [[ "$RELEASE_TEST_MODE" == asset-failure ]]; then exit 22; fi
            if [[ "$RELEASE_TEST_MODE" == wrong-binary ]]; then
                cp "$RELEASE_TEST_ASSETS/wrong-tree-sitter.gz" "$output"
            else
                cp "$RELEASE_TEST_ASSETS/tree-sitter.gz" "$output"
            fi
            ;;
        *) exit 22 ;;
    esac
fi
STUB
chmod +x "$TEST_ROOT/bin/"*
new_home() {
    mkdir -p "$1/.local/bin"
    printf '#!/bin/sh\nprintf "NVIM v9.0.0\\n"\n' > "$1/.local/bin/nvim"
    printf '#!/bin/sh\nprintf "tree-sitter 9.0.0\\n"\n' > "$1/.local/bin/tree-sitter"
    chmod +x "$1/.local/bin/"*
    cp "$1/.local/bin/nvim" "$1/original-nvim"
    cp "$1/.local/bin/tree-sitter" "$1/original-tree-sitter"
}
run_release() {
    # Positional parameters are expanded by the child shell.
    # shellcheck disable=SC2016
    env HOME="$1" PATH="$TEST_ROOT/bin:$PATH" RELEASE_TEST_LOG="$TEST_ROOT/http.log" \
        RELEASE_TEST_MODE="$2" RELEASE_TEST_ASSETS="$TEST_ROOT/assets" \
        bash -c 'source "$1"; INSTALL_DRY_RUN=$2; install_native_binaries linux' \
        bash "$PROJECT_ROOT/script/install-common.sh" "${3:-false}"
}

# Upgrade older valid versions to the actual resolved tag, retaining backups.
upgrade_home="$TEST_ROOT/upgrade home"
new_home "$upgrade_home"
run_release "$upgrade_home" success > "$TEST_ROOT/upgrade.log"
[[ $("$upgrade_home/.local/bin/nvim" --version) == 'NVIM v9.8.7' ]] || fail 'Neovim was not upgraded'
[[ $("$upgrade_home/.local/bin/tree-sitter" --version) == 'tree-sitter 9.7.6' ]] || fail 'tree-sitter was not upgraded'
backups=("$upgrade_home/.local/bin/nvim".backup.*)
cmp "$upgrade_home/original-nvim" "${backups[0]}" || fail 'Neovim backup changed'
backups=("$upgrade_home/.local/bin/tree-sitter".backup.*)
cmp "$upgrade_home/original-tree-sitter" "${backups[0]}" || fail 'tree-sitter backup changed'
[[ $(grep -c '/releases/download/' "$TEST_ROOT/http.log") == 2 ]] || fail 'unexpected asset downloads'
run_release "$upgrade_home" success >> "$TEST_ROOT/upgrade.log"
[[ $(grep -c '/releases/download/' "$TEST_ROOT/http.log") == 2 ]] || fail 'matching latest versions were downloaded again'

# Failures at metadata, compatibility, download, or binary validation preserve both tools.
for mode in metadata-failure invalid-tag old-tag asset-failure wrong-binary; do
    case_home="$TEST_ROOT/$mode home"
    new_home "$case_home"
    if run_release "$case_home" "$mode" > "$TEST_ROOT/$mode.log" 2>&1; then fail "accepted $mode"; fi
    cmp "$case_home/original-nvim" "$case_home/.local/bin/nvim" || fail "$mode changed Neovim"
    cmp "$case_home/original-tree-sitter" "$case_home/.local/bin/tree-sitter" || fail "$mode changed tree-sitter"
    [[ ! -e "$case_home/.local/opt" ]] || fail "$mode created an installation directory"
done

# A dry run is offline and creates no user files.
: > "$TEST_ROOT/http.log"
run_release "$TEST_ROOT/dry home" metadata-failure true > "$TEST_ROOT/dry.log"
[[ ! -s "$TEST_ROOT/http.log" && ! -e "$TEST_ROOT/dry home" ]] || fail 'dry run performed HTTP or writes'
printf 'PASS: latest release upgrades, repeat skips, failure preservation and offline dry run\n'
