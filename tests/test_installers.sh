#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin" "$TEST_ROOT/project with spaces"
cp -R "$PROJECT_ROOT/script" "$PROJECT_ROOT/nvim" "$PROJECT_ROOT/tests" "$TEST_ROOT/project with spaces/"
FIXTURE="$TEST_ROOT/project with spaces"
rm -f "$FIXTURE/nvim/lazy-lock.json"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Dry runs must not create config, shell profiles, downloads, or install tools.
for script in install-linux.sh install-macos.sh install-tools-linux.sh install-tools-macos.sh; do
    env -u NVIM_APPNAME HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/config" \
        XDG_DATA_HOME="$TEST_ROOT/data" bash "$FIXTURE/script/$script" --dry-run > "$TEST_ROOT/$script.log"
done
[[ -z $(ls -A "$TEST_ROOT/home") && ! -e "$TEST_ROOT/config" && ! -e "$TEST_ROOT/data" ]] \
    || fail 'dry run changed HOME/config/data'

# Stub executables isolate orchestration from downloads and host configuration.
cat > "$TEST_ROOT/bin/nvim" <<'STUB'
#!/usr/bin/env bash
if [[ ${1:-} == --version ]]; then printf 'NVIM v0.12.6\n'; exit 0; fi
printf '%s\n' "$*" >> "$INSTALL_TEST_LOG"
if [[ -n ${INSTALL_TEST_FAIL:-} && "$*" == *"$INSTALL_TEST_FAIL"* ]]; then exit 17; fi
STUB
cat > "$TEST_ROOT/bin/tree-sitter" <<'STUB'
#!/usr/bin/env bash
printf 'tree-sitter 0.26.1\n'
STUB
cat > "$TEST_ROOT/bin/fzf" <<'STUB'
#!/usr/bin/env bash
printf '0.44.1\n'
STUB
for tool in rust-analyzer rustfmt pyright-langserver fd rg git curl cc node npm; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_ROOT/bin/$tool"
done
chmod +x "$TEST_ROOT/bin/"*
run_installer() {
    env -u NVIM_APPNAME HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/config" \
        XDG_DATA_HOME="$TEST_ROOT/data" PATH="$TEST_ROOT/bin:$PATH" \
        INSTALL_TEST_LOG="$TEST_ROOT/nvim.log" INSTALL_TEST_FAIL="${1:-}" \
        bash "$FIXTURE/script/install-linux.sh" --skip-tools
}
run_installer > "$TEST_ROOT/install.log"
[[ "$TEST_ROOT/config/nvim" -ef "$FIXTURE/nvim" ]] || fail 'configuration not linked'
[[ $(wc -l < "$TEST_ROOT/nvim.log") == 5 ]] || fail 'missing plugins/parser/startup/search/compatibility steps'
sed -n '1p' "$TEST_ROOT/nvim.log" | grep -q 'Lazy! sync' || fail 'fresh install must sync without lock'
sed -n '1p' "$TEST_ROOT/nvim.log" | grep -q -- '-u NONE' || fail 'bootstrap must not load full configuration'
sed -n '3p' "$TEST_ROOT/nvim.log" | grep -q 'tests/test_config.lua' || fail 'startup check missing'
sed -n '4p' "$TEST_ROOT/nvim.log" | grep -q 'tests/test_search.lua' || fail 'search check missing'

sed -n '1p' "$TEST_ROOT/nvim.log" | grep -q 'vim.go.loadplugins = true' || fail 'bootstrap disabled Lazy loading'
sed -n '1p' "$TEST_ROOT/nvim.log" | grep -q 'cquit 1' || fail 'bootstrap errors must fail installation'

sed -n '5p' "$TEST_ROOT/nvim.log" | grep -q 'tests/test_compat.lua' || fail 'compatibility check missing'

# A locally generated lockfile selects restore on the next run.
printf '{}\n' > "$FIXTURE/nvim/lazy-lock.json"
: > "$TEST_ROOT/nvim.log"
run_installer > "$TEST_ROOT/reinstall.log"
sed -n '1p' "$TEST_ROOT/nvim.log" | grep -q 'Lazy! restore' || fail 'local lock must select restore'

# Plugin provisioning failures must stop before parser/startup checks.
rm "$FIXTURE/nvim/lazy-lock.json"
: > "$TEST_ROOT/nvim.log"
if run_installer 'Lazy! sync' > "$TEST_ROOT/plugins-failure.log" 2>&1; then fail 'plugin failure ignored'; fi
[[ $(wc -l < "$TEST_ROOT/nvim.log") == 1 ]] || fail 'continued after plugin failure'

: > "$TEST_ROOT/nvim.log"
if run_installer test_config.lua > "$TEST_ROOT/failure.log" 2>&1; then fail 'startup failure ignored'; fi
[[ $(wc -l < "$TEST_ROOT/nvim.log") == 3 ]] || fail 'continued after failed startup'

# A custom app name must fail before configuration changes.
if env NVIM_APPNAME=other HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/other-config" \
    bash "$FIXTURE/script/install-linux.sh" --skip-tools > "$TEST_ROOT/appname.log" 2>&1; then
    fail 'custom app name accepted'
fi
[[ ! -e "$TEST_ROOT/other-config" ]] || fail 'custom app name changed configuration'
printf 'PASS: installer dry runs, spaced paths, ordered checks and failure propagation\n'
