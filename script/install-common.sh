#!/usr/bin/env bash
# Shared by the Linux/macOS entry points; compatible with macOS Bash 3.2.
set -euo pipefail

INSTALL_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INSTALL_REPO_ROOT=$(cd -- "$INSTALL_SCRIPT_DIR/.." && pwd)
INSTALL_DRY_RUN=false
export INSTALL_SKIP_TOOLS=false
export PATH="$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"

install_usage() {
    printf 'Usage: bash %s [--dry-run] [--skip-tools] [--help]\n' "${0##*/}"
    printf '%s\n' 'Installs required tools, backs up and links configuration, restores plugins and checks startup.'
    printf '%s\n' '--dry-run prints the operations without changing files or installing packages.'
    printf '%s\n' '--skip-tools uses existing tools (full installers only); versions are still checked.'
}

install_parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --dry-run) INSTALL_DRY_RUN=true ;;
            --skip-tools) INSTALL_SKIP_TOOLS=true ;;
            -h|--help) install_usage; exit 0 ;;
            *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
        esac
    done
}

install_run() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    if ! "$INSTALL_DRY_RUN"; then "$@"; fi
}

install_require_platform() {
    if [[ ${NVIM_APPNAME:-nvim} != nvim ]]; then
        printf '%s\n' 'Unset NVIM_APPNAME before installing this configuration.' >&2
        exit 1
    fi
    if ! "$INSTALL_DRY_RUN" && [[ $(uname -s) != "$1" ]]; then
        printf 'This installer requires %s.\n' "$1" >&2
        exit 1
    fi
}

install_admin() {
    if [[ $(id -u) == 0 ]]; then install_run "$@"; else install_run sudo "$@"; fi
}

install_version_at_least() {
    local actual=$1 minimum=$2
    awk -v actual="$actual" -v minimum="$minimum" 'BEGIN {
        split(actual,a,"."); split(minimum,b,".");
        for(i=1;i<=3;i++){ if(a[i]+0>b[i]+0)exit 0; if(a[i]+0<b[i]+0)exit 1 } exit 0
    }'
}

install_binary_version() {
    local output
    output=$("$1" --version 2>/dev/null) || return
    printf '%s\n' "$output" | sed -n '1s/[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p'
}

install_backup() {
    if [[ -e "$1" || -L "$1" ]]; then
        local target
        target="$1.backup.$(date +%Y%m%d-%H%M%S).$$"
        while [[ -e "$target" || -L "$target" ]]; do target="$target.1"; done
        mv -- "$1" "$target"
        printf 'Backed up %s to %s\n' "$1" "$target"
    fi
}

install_link() {
    local source=$1 target=$2
    if [[ -L "$target" && "$target" -ef "$source" ]]; then return; fi
    install_backup "$target"
    ln -s -- "$source" "$target"
}

# GitHub documents /releases/latest as the stable release permalink:
# https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases
install_latest_release() {
    local repository=$1 minimum=$2 url tag version
    url=$(curl --fail --silent --show-error --location --head --retry 3 \
        --output /dev/null --write-out '%{url_effective}' \
        "https://github.com/$repository/releases/latest") || {
        printf 'Could not resolve the latest release of %s.\n' "$repository" >&2
        return 1
    }
    case "$url" in
        "https://github.com/$repository/releases/tag/"*) tag=${url##*/} ;;
        *) printf 'Unexpected release URL for %s: %s\n' "$repository" "$url" >&2; return 1 ;;
    esac
    if [[ ! "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        printf 'Unsupported stable release tag for %s: %s\n' "$repository" "$tag" >&2
        return 1
    fi
    version=${tag#v}
    if ! install_version_at_least "$version" "$minimum"; then
        printf 'Latest %s release %s is below the required minimum %s.\n' "$repository" "$tag" "$minimum" >&2
        return 1
    fi
    printf '%s\n' "$tag"
}

install_native_binaries() {
    local platform=$1 arch nvim_arch ts_arch temp target current
    local nvim_tag ts_tag nvim_version ts_version need_nvim=false need_ts=false staged_version
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) nvim_arch=x86_64; ts_arch=x64 ;;
        arm64|aarch64) nvim_arch=arm64; ts_arch=arm64 ;;
        *) printf 'Unsupported architecture: %s (supported: x86_64, arm64)\n' "$arch" >&2; exit 1 ;;
    esac
    if "$INSTALL_DRY_RUN"; then
        printf 'Resolve latest stable Neovim (%s-%s) and tree-sitter CLI releases; install or upgrade older binaries in ~/.local.\n' \
            "$platform" "$nvim_arch"
        return
    fi
    # Resolve both versions before changing any installed files.
    nvim_tag=$(install_latest_release neovim/neovim 0.12.0) || return 1
    ts_tag=$(install_latest_release tree-sitter/tree-sitter 0.26.1) || return 1
    nvim_version=${nvim_tag#v}
    ts_version=${ts_tag#v}
    printf 'Latest stable releases: Neovim %s, tree-sitter %s.\n' "$nvim_tag" "$ts_tag"
    current=$(install_binary_version nvim || true)
    if [[ -z "$current" ]] || ! install_version_at_least "$current" "$nvim_version"; then need_nvim=true; fi
    current=$(install_binary_version tree-sitter || true)
    if [[ -z "$current" ]] || ! install_version_at_least "$current" "$ts_version"; then need_ts=true; fi
    if ! "$need_nvim" && ! "$need_ts"; then
        printf '%s\n' 'Installed Neovim and tree-sitter are already at or newer than the latest stable releases.'
        return
    fi
    temp=$(mktemp -d)
    (
        trap 'rm -rf -- "$temp"' EXIT
        # Stage and validate all needed downloads before replacing either binary.
        if "$need_nvim"; then
            curl --fail --location --retry 3 --output "$temp/nvim.tar.gz" \
                "https://github.com/neovim/neovim/releases/download/$nvim_tag/nvim-$platform-$nvim_arch.tar.gz" || {
                printf 'Neovim asset download failed for %s (%s-%s).\n' "$nvim_tag" "$platform" "$nvim_arch" >&2
                exit 1
            }
            tar -xzf "$temp/nvim.tar.gz" -C "$temp"
            staged_version=$(install_binary_version "$temp/nvim-$platform-$nvim_arch/bin/nvim")
            if [[ "$staged_version" != "$nvim_version" ]]; then
                printf 'Neovim asset version mismatch: expected %s, found %s.\n' "$nvim_version" "$staged_version" >&2
                exit 1
            fi
        fi
        if "$need_ts"; then
            curl --fail --location --retry 3 --output "$temp/tree-sitter.gz" \
                "https://github.com/tree-sitter/tree-sitter/releases/download/$ts_tag/tree-sitter-$platform-$ts_arch.gz" || {
                printf 'tree-sitter asset download failed for %s (%s-%s).\n' "$ts_tag" "$platform" "$ts_arch" >&2
                exit 1
            }
            gzip -dc "$temp/tree-sitter.gz" > "$temp/tree-sitter"
            chmod +x "$temp/tree-sitter"
            staged_version=$(install_binary_version "$temp/tree-sitter")
            if [[ "$staged_version" != "$ts_version" ]]; then
                printf 'tree-sitter asset version mismatch: expected %s, found %s.\n' "$ts_version" "$staged_version" >&2
                exit 1
            fi
        fi
        mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
        if "$need_nvim"; then
            target="$HOME/.local/opt/nvim-$nvim_version"
            install_backup "$target"
            mv "$temp/nvim-$platform-$nvim_arch" "$target"
            install_link "$target/bin/nvim" "$HOME/.local/bin/nvim"
        fi
        if "$need_ts"; then
            install_backup "$HOME/.local/bin/tree-sitter"
            mv "$temp/tree-sitter" "$HOME/.local/bin/tree-sitter"
        fi
    )
}

install_language_tools() {
    if "$INSTALL_DRY_RUN"; then
        printf '%s\n' 'Install rustup if absent, rustfmt/rust-analyzer components, and Pyright via npm --prefix ~/.local.'
        return
    fi
    if ! command -v rustup >/dev/null 2>&1; then
        local temp
        temp=$(mktemp -d)
        (
            trap 'rm -rf -- "$temp"' EXIT
            curl --proto '=https' --tlsv1.2 --fail --location https://sh.rustup.rs -o "$temp/rustup-init.sh"
            sh "$temp/rustup-init.sh" -y --profile minimal --default-toolchain stable --no-modify-path
        )
    fi
    if ! rustup show active-toolchain >/dev/null 2>&1; then
        rustup toolchain install stable --profile minimal
        rustup default stable
    fi
    rustup component add rustfmt rust-analyzer
    npm install --global --prefix "$HOME/.local" pyright
}

install_persist_path() {
    if "$INSTALL_DRY_RUN"; then
        printf '%s\n' 'Add an idempotent nvim-simple-mode PATH snippet to ~/.profile, ~/.bashrc, ~/.zprofile, ~/.zshrc (and existing ~/.bash_profile).'
        return
    fi
    local dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim-simple-mode" profile line
    mkdir -p "$dir"
    cat > "$dir/env.sh" <<'ENV'
# Installed by nvim_simple_mode; user-local Neovim, search tools, npm and Rust.
export PATH="$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
ENV
    # Evaluate HOME/XDG_CONFIG_HOME when the shell starts, not during installation.
    # shellcheck disable=SC2016
    line='[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-simple-mode/env.sh" ] || . "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-simple-mode/env.sh"'
    for profile in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.zshrc"; do
        if ! grep -Fqx "$line" "$profile" 2>/dev/null; then printf '\n%s\n' "$line" >> "$profile"; fi
    done
    if [[ -f "$HOME/.bash_profile" ]] && ! grep -Fqx "$line" "$HOME/.bash_profile"; then
        printf '\n%s\n' "$line" >> "$HOME/.bash_profile"
    fi
}

install_check_tools() {
    if "$INSTALL_DRY_RUN"; then
        printf '%s\n' 'Check Neovim >=0.12, tree-sitter >=0.26.1, fd, rg, fzf >=0.36, Git, curl, C compiler, Node/npm, rust-analyzer, rustfmt and Pyright.'
        return
    fi
    local tool version
    for tool in nvim tree-sitter fd rg fzf git curl cc node npm rust-analyzer rustfmt pyright-langserver; do
        command -v "$tool" >/dev/null 2>&1 || { printf 'Missing required executable: %s\n' "$tool" >&2; return 1; }
    done
    version=$(install_binary_version nvim)
    install_version_at_least "$version" 0.12.0 || { printf 'Neovim >=0.12 required; found %s.\n' "$version" >&2; return 1; }
    version=$(install_binary_version tree-sitter)
    install_version_at_least "$version" 0.26.1 || { printf 'tree-sitter >=0.26.1 required; found %s.\n' "$version" >&2; return 1; }
    version=$(install_binary_version fzf)
    install_version_at_least "$version" 0.36.0 || { printf 'fzf >=0.36 required; found %s. Update your distro/Homebrew package.\n' "$version" >&2; return 1; }
    rust-analyzer --version
    rustfmt --version
}

install_config_and_plugins() {
    install_check_tools
    install_run bash "$INSTALL_SCRIPT_DIR/setup_init_file.sh"
    # Keep tests in separate processes: each starts from a fresh editor state.
    if "$INSTALL_DRY_RUN"; then
        printf '%s\n' 'Restore locked plugins, await Markdown parser installation, then run both startup and search tests.'
        return
    fi
    (
        cd "$INSTALL_REPO_ROOT"
        nvim --headless '+Lazy! restore' '+qa!'
        nvim --headless '+lua require("nvim-treesitter").install({"markdown", "markdown_inline"}):wait(300000)' '+qa!'
        nvim --headless '+luafile tests/test_config.lua' '+qa!'
        nvim --headless '+luafile tests/test_search.lua' '+qa!'
    )
    printf '%s\n' 'Installation and startup checks complete. Open a new terminal, then run nvim.'
}
