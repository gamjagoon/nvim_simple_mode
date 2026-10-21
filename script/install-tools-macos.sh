#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/install-common.sh"
install_parse_args "$@"
install_require_platform Darwin
if "$INSTALL_SKIP_TOOLS"; then printf '%s\n' '--skip-tools is only valid for install-macos.sh.' >&2; exit 2; fi
export PATH="$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
# The current upstream Homebrew bootstrap supports Apple Silicon only.
# Intel users can use an existing working Homebrew or provision tools and --skip-tools.
if ! "$INSTALL_DRY_RUN" && ! command -v brew >/dev/null 2>&1 && [[ $(uname -m) != arm64 ]]; then
    printf '%s\n' 'Intel macOS requires an existing working Homebrew installation.' >&2
    printf '%s\n' 'The current Homebrew bootstrap supports Apple Silicon only; alternatively provision tools and use install-macos.sh --skip-tools.' >&2
    exit 1
fi
if ! "$INSTALL_DRY_RUN" && ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install
    printf '%s\n' 'Finish installing Apple Command Line Tools in the opened dialog, then rerun this script.' >&2
    exit 1
fi
if ! "$INSTALL_DRY_RUN" && ! command -v brew >/dev/null 2>&1; then
    temp=$(mktemp -d)
    trap 'rm -rf -- "$temp"' EXIT
    curl --fail --location https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$temp/brew-install.sh"
    /bin/bash "$temp/brew-install.sh"
fi
install_run brew install git curl fd ripgrep fzf node
install_native_binaries macos
install_language_tools
install_persist_path
install_check_tools
# macOS provides pbcopy/pbpaste without an extra clipboard package.
