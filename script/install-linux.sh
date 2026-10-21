#!/usr/bin/env bash
set -euo pipefail
# shellcheck source-path=SCRIPTDIR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/install-common.sh"
install_parse_args "$@"
install_require_platform Linux
if ! "$INSTALL_SKIP_TOOLS"; then
    if "$INSTALL_DRY_RUN"; then
        bash "$INSTALL_SCRIPT_DIR/install-tools-linux.sh" --dry-run
    else
        bash "$INSTALL_SCRIPT_DIR/install-tools-linux.sh"
    fi
fi
install_config_and_plugins
