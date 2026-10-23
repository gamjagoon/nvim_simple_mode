#!/usr/bin/env bash
# Install optional Ubuntu/Debian notification tools without sudo.
set -euo pipefail
if [[ ${1:-} == --help ]]; then
    echo 'Usage: bash script/setup-notification-tools.sh'
    echo 'Installs user-local OS notification/audio tools and starts dunst if no notification service exists.'
    exit 0
fi
if [[ $# != 0 ]]; then echo 'Unsupported argument' >&2; exit 2; fi
for tool in apt-get dpkg-deb ldd python3 busctl systemctl fc-cache; do
    command -v "$tool" >/dev/null || { echo "Required tool missing: $tool" >&2; exit 1; }
done
prefix="$HOME/.local/opt/earlgrey-notify"
mkdir -p "$prefix/packages" "$HOME/.local/bin"
(
    cd "$prefix/packages"
    apt-get download libnotify-bin pulseaudio-utils dunst sound-theme-freedesktop fonts-nanum
    for package in ./*.deb; do dpkg-deb -x "$package" "$prefix/root"; done
)
for tool in notify-send paplay pactl parec dunst dunstctl; do
    binary="$prefix/root/usr/bin/$tool"
    if ldd "$binary" 2>/dev/null | grep -q 'not found'; then
        echo "Missing shared libraries for $binary; install the reported dependencies with your package manager." >&2
        ldd "$binary" >&2
        exit 1
    fi
done
python3 - <<'PY'
from pathlib import Path
import shlex
root = Path.home()/'.local/opt/earlgrey-notify/root'
for name in ['notify-send', 'paplay', 'pactl', 'parec', 'dunst', 'dunstctl']:
    target = Path.home()/'.local/bin'/name
    marker = '# earlgrey notification tools'
    if target.exists() or target.is_symlink():
        if target.is_symlink() or marker not in target.read_text(errors='replace'):
            print('Preserving existing executable:', target)
            continue
    content = '#!/bin/sh\n' + marker + '\n'
    if name in ['paplay', 'pactl', 'parec']:
        content += 'if [ -z "${PULSE_SERVER:-}" ] && [ -S /mnt/wslg/PulseServer ]; then\n  export PULSE_SERVER=unix:/mnt/wslg/PulseServer\nfi\n'
    content += 'exec ' + shlex.quote(str(root/'usr/bin'/name)) + ' "$@"\n'
    target.write_text(content)
    target.chmod(0o755)
PY
mkdir -p "$HOME/.local/share/fonts/earlgrey-notify"
for font in "$prefix/root/usr/share/fonts/truetype/nanum/"*.ttf; do
    target="$HOME/.local/share/fonts/earlgrey-notify/${font##*/}"
    if [[ ! -e "$target" ]]; then cp "$font" "$target"; fi
done
fc-cache -f "$HOME/.local/share/fonts/earlgrey-notify"
export PATH="$HOME/.local/bin:$PATH"
if [[ -S /mnt/wslg/runtime-dir/wayland-0 ]]; then
    # GTK normal windows work through WSLg's native Wayland connection.
    if ! command -v zenity >/dev/null; then
        (cd "$prefix/packages"; apt-get download zenity zenity-common)
        for package in "$prefix/packages"/zenity*.deb; do dpkg-deb -x "$package" "$prefix/root"; done
        if ldd "$prefix/root/usr/bin/zenity" | grep -q 'not found'; then
            echo 'Zenity requires additional shared libraries; install zenity with your package manager.' >&2
            exit 1
        fi
        if [[ ! -e "$HOME/.local/bin/zenity" ]]; then
            ln -s "$prefix/root/usr/bin/zenity" "$HOME/.local/bin/zenity"
        fi
    fi
    echo 'WSLg: native Wayland popup and Korean fonts ready; using PulseAudio RDP sound.'
    exit 0
fi
if busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus NameHasOwner s org.freedesktop.Notifications | grep -q true; then
    echo 'Using existing OS notification service.'
else
    config="${XDG_CONFIG_HOME:-$HOME/.config}/earlgrey.nvim"
    units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    mkdir -p "$config" "$units"
    # Preserve user edits on repeat setup.
    if [[ ! -e "$config/dunstrc" ]]; then
        cat > "$config/dunstrc" <<'CONFIG'
[global]
    force_xwayland = true
    origin = top-right
    width = 420
    height = 120
    font = Sans 12
[urgency_normal]
    timeout = 10
CONFIG
    fi
    display=${DISPLAY:-}
    if [[ -z "$display" && -S /tmp/.X11-unix/X0 ]]; then display=:0; fi
    if [[ -z "$display" ]]; then echo 'No X11 display; OS popup service could not start.' >&2; exit 1; fi
    # systemd quotes and percent expansion differ from shell quoting.
    export EARLGREY_NOTIFICATION_DISPLAY="$display"
    export EARLGREY_NOTIFICATION_CONFIG="$config"
    export EARLGREY_NOTIFICATION_UNITS="$units"
    python3 - <<'PY'
from pathlib import Path
import os
import json
unit = Path(os.environ['EARLGREY_NOTIFICATION_UNITS'])/'earlgrey-notifications.service'
marker = '# earlgrey notification service'
if unit.exists() and not unit.read_text().startswith(marker):
    raise SystemExit('Refusing to replace existing unit: ' + str(unit))
def quote(value):
    return json.dumps(value).replace('%', '%%')
config = Path(os.environ['EARLGREY_NOTIFICATION_CONFIG'])/'dunstrc'
program = Path.home()/'.local/opt/earlgrey-notify/root/usr/bin/dunst'
unit.write_text(marker + '\n[Unit]\nDescription=Earlgrey OS notifications\n\n[Service]\nType=dbus\nBusName=org.freedesktop.Notifications\nEnvironment=' + quote('DISPLAY='+os.environ['EARLGREY_NOTIFICATION_DISPLAY']) + '\nExecStart=' + quote(str(program)) + ' -config ' + quote(str(config)) + '\nRestart=on-failure\n\n[Install]\nWantedBy=default.target\n')
PY
    systemctl --user daemon-reload
    systemctl --user enable --now earlgrey-notifications.service
fi
printf '%s\n' 'Tools installed in ~/.local/bin; OS popup service is ready.'
printf '%s\n' 'WSLg audio clients use /mnt/wslg/PulseServer when PULSE_SERVER is unset.'
