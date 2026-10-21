#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/install-common.sh"
install_parse_args "$@"
install_require_platform Linux
if "$INSTALL_SKIP_TOOLS"; then printf '%s\n' '--skip-tools is only valid for install-linux.sh.' >&2; exit 2; fi

if command -v apt-get >/dev/null 2>&1; then
    install_admin apt-get update
    install_admin apt-get install -y git curl ca-certificates tar gzip build-essential fd-find ripgrep fzf nodejs npm xclip wl-clipboard
elif command -v dnf >/dev/null 2>&1; then
    install_admin dnf install -y git curl ca-certificates tar gzip gcc gcc-c++ make fd-find ripgrep fzf nodejs npm xclip wl-clipboard
elif command -v pacman >/dev/null 2>&1; then
    install_admin pacman -S --needed --noconfirm git curl ca-certificates tar gzip base-devel fd ripgrep fzf nodejs npm xclip wl-clipboard
else
    printf '%s\n' 'Supported Linux package managers: apt-get, dnf, pacman.' >&2
    exit 1
fi
if "$INSTALL_DRY_RUN"; then
    printf '%s\n' 'Expose fdfind as ~/.local/bin/fd when the distro does not provide fd.'
elif ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    install_link "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
install_native_binaries linux
install_language_tools
install_persist_path
install_check_tools
