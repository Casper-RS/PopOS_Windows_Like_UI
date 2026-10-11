#!/bin/sh
# Install the Windows-like UI Flatpak and switch the COSMIC panel layout to it.
#
#   ./scripts/install.sh                 install the latest release bundle
#   ./scripts/install.sh --bundle FILE   install a local .flatpak bundle
#   ./scripts/install.sh --build         build from source with flatpak-builder
#   ./scripts/install.sh --layout-only   only apply the panel layout and shortcuts
set -eu

APP=io.github.casper_rs.PopOSWindowsLikeUI
REPO=Casper-RS/PopOS_Windows_Like_UI
CFG="$HOME/.config/cosmic"
BACKUP="$HOME/.config/cosmic-windows-like-ui-backup"
HERE=$(cd "$(dirname "$0")/.." && pwd)

mode=release
bundle=""
case "${1:-}" in
    --bundle) mode=bundle; bundle=${2:?--bundle needs a file} ;;
    --build) mode=build ;;
    --layout-only) mode=none ;;
    "") ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

case $mode in
    release)
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        echo "Downloading the latest release..."
        curl -fL -o "$tmp/$APP.flatpak" \
            "https://github.com/$REPO/releases/latest/download/$APP.flatpak"
        flatpak install --user -y --noninteractive "$tmp/$APP.flatpak"
        ;;
    bundle)
        flatpak install --user -y --noninteractive "$bundle"
        ;;
    build)
        flatpak install --user -y --noninteractive flathub org.flatpak.Builder
        build="$HOME/.cache/$APP-build"
        mkdir -p "$build"
        flatpak run --filesystem="$HERE" --filesystem="$build" \
            --env=FLATPAK_USER_DIR="$HOME/.local/share/flatpak" --command=sh org.flatpak.Builder -c \
            "cd '$HERE/flatpak' && flatpak-builder --user --install --install-deps-from=flathub \
             --force-clean --state-dir='$build/state' '$build/builddir' $APP.yml"
        ;;
esac

# Keep the original panel and shortcut configuration once, for uninstall.sh.
if [ ! -d "$BACKUP" ]; then
    mkdir -p "$BACKUP"
    for d in com.system76.CosmicPanel com.system76.CosmicPanel.Dock com.system76.CosmicPanel.Panel \
             com.system76.CosmicSettings.Shortcuts; do
        [ -d "$CFG/$d" ] && cp -a "$CFG/$d" "$BACKUP/"
    done
    echo "Backed up your panel configuration to $BACKUP"
fi

# One bottom taskbar, no top bar.
mkdir -p "$CFG/com.system76.CosmicPanel/v1" "$CFG/com.system76.CosmicPanel.Dock/v1"
printf '[\n    "Dock",\n]' > "$CFG/com.system76.CosmicPanel/v1/entries"

dock="$CFG/com.system76.CosmicPanel.Dock/v1"
set_key() { printf '%s' "$2" > "$dock/$1"; }
set_key name '"Dock"'
set_key anchor Bottom
set_key anchor_gap false
set_key autohide Never
set_key background ThemeDefault
set_key border_radius 0
set_key exclusive_zone true
set_key expand_to_edges true
set_key margin 0
set_key opacity 1.0
set_key output All
set_key padding 2
set_key spacing 0
[ -f "$dock/size" ] || set_key size M
set_key plugins_center 'Some([])'

battery=""
if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    battery='    "com.system76.CosmicAppletBattery",
'
fi
cat > "$dock/plugins_wings" <<WINGS
Some(([
    "$APP.Start",
    "$APP.Search",
    "$APP.Taskbar",
], [
    "$APP.StatusHub",
    "$APP.Keyboard",
    "$APP.SystemMonitor",
    "com.system76.CosmicAppletNetwork",
    "com.system76.CosmicAppletBluetooth",
${battery}    "com.system76.CosmicAppletAudio",
    "com.system76.CosmicAppletTime",
    "com.system76.CosmicAppletNotifications",
]))
WINGS

# Windows-style shortcuts, added to any custom shortcuts you already have.
sc="$CFG/com.system76.CosmicSettings.Shortcuts/v1"
mkdir -p "$sc"
[ -s "$sc/custom" ] || printf '{\n}\n' > "$sc/custom"
add_shortcut() {
    grep -qF "$1" "$sc/custom" && return
    # Insert before the closing brace of the map.
    awk -v line="    $1" '{ lines[NR] = $0 } END {
        last = NR; while (last > 0 && lines[last] !~ /}/) last--
        for (i = 1; i <= NR; i++) { if (i == last) print line; print lines[i] } }' \
        "$sc/custom" > "$sc/custom.new" && mv "$sc/custom.new" "$sc/custom"
}
add_shortcut '(modifiers: [Super], key: "i"): Spawn("cosmic-settings"),'
add_shortcut '(modifiers: [Super], key: "l"): System(LockScreen),'
add_shortcut '(modifiers: [Super, Shift], key: "l"): System(LogOut),'

echo
echo "Done. Log out and back in to finish (the notifications icon needs a fresh session)."
