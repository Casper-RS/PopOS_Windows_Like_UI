#!/bin/sh
# Restore the panel layout and shortcuts from before install.sh, and remove the Flatpak.
set -eu

APP=io.github.casper_rs.PopOSWindowsLikeUI
CFG="$HOME/.config/cosmic"
BACKUP="$HOME/.config/cosmic-windows-like-ui-backup"

if [ -d "$BACKUP" ]; then
    for d in com.system76.CosmicPanel com.system76.CosmicPanel.Dock com.system76.CosmicPanel.Panel \
             com.system76.CosmicSettings.Shortcuts; do
        rm -rf "${CFG:?}/$d"
        [ -d "$BACKUP/$d" ] && cp -a "$BACKUP/$d" "$CFG/"
    done
    rm -rf "$BACKUP"
    echo "Restored your previous panel configuration."
else
    echo "No backup found; leaving the panel configuration as it is." >&2
fi

rm -f "$HOME/.config/autostart/$APP.Clipboard.desktop"
if [ -f "$HOME/.local/share/windows-like-ui/lockscreen-installed" ]; then
    rm -f "$HOME/.local/bin/cosmic-greeter"
    pkill -x -u "$(id -un)" cosmic-greeter || true
    echo "Restored the stock lock screen."
fi
rm -rf "$HOME/.local/share/windows-like-ui"
flatpak kill "$APP" 2>/dev/null || true
flatpak uninstall --user -y --noninteractive "$APP" || true
echo "Done. Log out and back in to finish."
echo "Autologin, if you enabled it, stays on; turn it off with ./scripts/autologin.sh --undo"
