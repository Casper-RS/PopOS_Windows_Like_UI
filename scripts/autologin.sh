#!/bin/sh
# Log in automatically after the disk-encryption password, so you only type a
# password once per boot. Also removes the keyring password so Chrome and
# other apps stop asking for it.
#
#   ./scripts/autologin.sh           enable (asks for sudo)
#   ./scripts/autologin.sh --undo    disable autologin again
#
# Refuses to run when the system disk isn't encrypted: autologin would then
# let anyone who turns the machine on into your account.
set -eu

CONF=/etc/greetd/cosmic-greeter.toml
# greetd's initial_session doesn't set XDG_SESSION_TYPE, so logind registers
# the session as "tty" and the compositor can't get the GPU back after sleep
# (screens wake up black). pam_env sets it before pam_systemd runs.
PAM=/etc/pam.d/cosmic-greeter
SESSION_ENV=/etc/greetd/autologin-session.env
HERE=$(cd "$(dirname "$0")" && pwd)
USER_NAME=$(id -un)

if [ "${1:-}" = "--undo" ]; then
    sudo sed -i '/^\[initial_session\]/,$d' "$CONF"
    sudo sed -i "\#$SESSION_ENV#d" "$PAM"
    sudo rm -f "$SESSION_ENV"
    echo "Autologin disabled. To protect the keyring with your password again, change it in"
    echo "Passwords and Keys (seahorse) or run: $HERE/keyring-no-password and enter a new password."
    exit 0
fi

[ -f "$CONF" ] || { echo "$CONF not found: this needs the COSMIC greeter." >&2; exit 1; }

root_dev=$(findmnt -no SOURCE /)
if ! lsblk -sno TYPE "$root_dev" 2>/dev/null | grep -qx crypt; then
    echo "The system disk is not encrypted; not enabling autologin." >&2
    exit 1
fi

if grep -q '^\[initial_session\]' "$CONF"; then
    echo "Autologin is already enabled."
else
    sudo cp "$CONF" "$CONF.bak"
    printf '\n[initial_session]\ncommand = "start-cosmic"\nuser = "%s"\n' "$USER_NAME" |
        sudo tee -a "$CONF" >/dev/null
    echo "Autologin enabled; it starts working on the next boot."
fi

if ! grep -q "$SESSION_ENV" "$PAM"; then
    echo 'XDG_SESSION_TYPE=wayland' | sudo tee "$SESSION_ENV" >/dev/null
    sudo sed -i "/^@include common-session/i session required pam_env.so readenv=1 envfile=$SESSION_ENV" "$PAM"
    echo "Session type set to wayland (fixes a black screen after sleep); reboot to apply."
fi

"$HERE/keyring-no-password" || true
