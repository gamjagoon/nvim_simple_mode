#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/install-common.sh"
install_parse_args "$@"
install_require_platform Darwin
export PATH="$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! "$INSTALL_SKIP_TOOLS"; then
    if "$INSTALL_DRY_RUN"; then
        bash "$INSTALL_SCRIPT_DIR/install-tools-macos.sh" --dry-run
    else
        bash "$INSTALL_SCRIPT_DIR/install-tools-macos.sh"
    fi
fi
install_config_and_plugins
