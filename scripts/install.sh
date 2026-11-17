#!/bin/sh
# Install the Windows-like UI Flatpak and switch the COSMIC panel layout to it.
#
#   ./scripts/install.sh                 install the latest release bundle
#   ./scripts/install.sh --bundle FILE   install a local .flatpak bundle
#   ./scripts/install.sh --build         build from source with flatpak-builder
#   ./scripts/install.sh --layout-only   only apply the panel layout and shortcuts
#
# Search style (remembered for the next run; combine with any option above):
#   --search box|shortcut   box: search box on the taskbar (default)
#                           shortcut: no box, Ctrl+Super+F opens the centered search panel
#
# Also installs the lock screen (a patched cosmic-greeter in ~/.local/bin; skip it with
# NO_LOCKSCREEN=1). Autologin is separate: ./scripts/autologin.sh
set -eu

APP=io.github.casper_rs.PopOSWindowsLikeUI
REPO=Casper-RS/PopOS_Windows_Like_UI
CFG="$HOME/.config/cosmic"
BACKUP="$HOME/.config/cosmic-windows-like-ui-backup"
HERE=$(cd "$(dirname "$0")/.." && pwd)

mode=release
bundle=""
SETTINGS="$HOME/.config/windows-like-ui"
mkdir -p "$SETTINGS"
search=$(cat "$SETTINGS/search-mode" 2>/dev/null || echo box)
while [ $# -gt 0 ]; do
    case $1 in
        --bundle) mode=bundle; bundle=${2:?--bundle needs a file}; shift ;;
        --build) mode=build ;;
        --layout-only) mode=none ;;
        --search) search=${2:?--search needs box or shortcut}; shift ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
case $search in box|shortcut) ;; *) echo "--search must be box or shortcut" >&2; exit 2 ;; esac
echo "$search" > "$SETTINGS/search-mode"

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

# One bottom taskbar.
mkdir -p "$CFG/com.system76.CosmicPanel/v1" "$CFG/com.system76.CosmicPanel.Dock/v1"
printf '[\n    "Dock",\n]' > "$CFG/com.system76.CosmicPanel/v1/entries"

# Common panel settings; the panel name is the first argument.
panel_base() {
    d="$CFG/com.system76.CosmicPanel.$1/v1"
    set_key() { printf '%s' "$2" > "$d/$1"; }
    set_key name "\"$1\""
    set_key anchor "$2"
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
    set_key keep_style_on_maximize false
}
panel_base Dock Bottom
dock="$CFG/com.system76.CosmicPanel.Dock/v1"
[ -f "$dock/size" ] || printf M > "$dock/size"

battery=""
if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    battery='    "com.system76.CosmicAppletBattery",
'
fi
# The search applet always runs (it hosts the Ctrl+Super+F panel); in shortcut mode
# it draws nothing, so it goes last where its 1px leaves no gap.
if [ "$search" = box ]; then
    search_start="    \"$APP.Search\","; search_end=""
else
    search_start=""; search_end="    \"$APP.Search\","
fi
printf 'Some([])' > "$dock/plugins_center"
# Like Windows 11: one clock button opens Wi-Fi, Bluetooth, sound, brightness and
# the calendar, with a "show desktop" strip at the far right.
cat > "$dock/plugins_wings" <<WINGS
Some(([
    "$APP.Start",
$search_start
    "$APP.Taskbar",
], [
    "$APP.StatusHub",
    "$APP.Keyboard",
    "$APP.SystemMonitor",
${battery}    "com.system76.CosmicAppletNotifications",
    "$APP.Flyout",
    "$APP.Desktop",
$search_end
]))
WINGS

# The taskbar is 95% opaque and hidden until you hover the screen edge; windows
# use the whole screen (no reserved space) and the bar slides over them.
printf 0.95 > "$dock/opacity"
printf Always > "$dock/autohide"
printf false > "$dock/exclusive_zone"
printf '(\n    wait_time: 1000,\n    transition_time: 100,\n    handle_size: 4,\n    unhide_delay: 0,\n)' > "$dock/autohide_behavior"

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
add_shortcut "(modifiers: [Ctrl, Super], key: \"f\"): Spawn(\"gdbus emit --session \
--object-path /$(echo "$APP.Search" | tr . /) --signal $APP.Search.Open\"),"
# Real monitor brightness over DDC/CI (used by these keys and the bar's slider).
install -D -m 755 "$HERE/scripts/wlui-brightness" "$HOME/.local/share/windows-like-ui/brightness"
add_shortcut '(modifiers: [Super], key: "Page_Up"): Spawn("sh -c '"'"'exec sh ~/.local/share/windows-like-ui/brightness up'"'"'"),'
add_shortcut '(modifiers: [Super], key: "Page_Down"): Spawn("sh -c '"'"'exec sh ~/.local/share/windows-like-ui/brightness down'"'"'"),'
command -v ddcutil >/dev/null || echo "Note: brightness needs ddcutil (sudo apt install ddcutil) and i2c access:" \
    "echo 'KERNEL==\"i2c-[0-9]*\", TAG+=\"uaccess\"' | sudo tee /etc/udev/rules.d/60-i2c-uaccess.rules"
add_shortcut "(modifiers: [Super], key: \"v\"): Spawn(\"gdbus call --session --dest $APP.Clipboard \
--object-path /$(echo "$APP.Clipboard" | tr . /) --method org.freedesktop.DbusActivation.ActivateAction show [] {}\"),"

# Clipboard history runs from login, so it sees everything copied.
# COSMIC 1.10 hides layer-shell, data-control and virtual-keyboard from Flatpak's
# sandboxed Wayland socket, so the launcher hands it the real compositor socket.
# It goes through a hard link in a private dir: exposing xdg-run/wayland-N itself
# leaves a stub where the panel applets (same app ID) expect their socket, and
# Start then crashes with NoCompositor when the clipboard starts first.
LAUNCHER="$HOME/.local/share/windows-like-ui/clipboard-start"
mkdir -p "$(dirname "$LAUNCHER")"
cat > "$LAUNCHER" <<LAUNCHER
#!/bin/sh
display=\${WAYLAND_DISPLAY:-wayland-0}
dir=\$XDG_RUNTIME_DIR/windows-like-ui
mkdir -p "\$dir" && ln -f "\$XDG_RUNTIME_DIR/\$display" "\$dir/\$display" || exit 1
# At login the compositor may not be ready yet, so retry a few times.
for i in 1 2 3 4 5 6 7 8 9 10; do
    flatpak run --nosocket=wayland --filesystem=xdg-run/windows-like-ui --command=sh $APP \\
        -c "WAYLAND_DISPLAY=windows-like-ui/\$display exec wlui-clipboard" && exit 0
    sleep 3
done
exit 1
LAUNCHER
chmod +x "$LAUNCHER"
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/$APP.Clipboard.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Clipboard history (Windows-like)
Exec=$LAUNCHER
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESKTOP

# Lock screen: cosmic-session starts `cosmic-greeter` from PATH, so a copy in
# ~/.local/bin replaces the stock lock screen for this user only (the login
# screen is untouched). Only for the COSMIC version the patch was made for.
greeter_version=$(dpkg-query -W -f='${Version}' cosmic-greeter 2>/dev/null || true)
if [ "${NO_LOCKSCREEN:-}" = 1 ] || [ "$mode" = none ]; then
    :
elif [ "${greeter_version#1.10.}" = "$greeter_version" ]; then
    echo "Skipping the lock screen: it is made for COSMIC 1.10, this system has cosmic-greeter ${greeter_version:-(none)}."
else
    mkdir -p "$HOME/.local/bin"
    dest="$HOME/.local/bin/cosmic-greeter"
    # Prefer the release binary; build it (a few minutes) when there is none.
    if [ "$mode" = build ] || ! curl -fsL -o "$dest.new" \
            "https://github.com/$REPO/releases/latest/download/cosmic-greeter-lockscreen"; then
        echo "Building the lock screen..."
        bin=$("$HERE/lockscreen/build.sh" --sdk | tail -n 1)
        cp "$bin" "$dest.new"
    fi
    chmod 755 "$dest.new"
    # Never swap in a binary that can't even start (missing libraries etc.).
    if "$dest.new" --help >/dev/null 2>&1; then
        mv "$dest.new" "$dest"
        mkdir -p "$HOME/.local/share/windows-like-ui"
        touch "$HOME/.local/share/windows-like-ui/lockscreen-installed"
        # cosmic-session restarts it right away with the new binary.
        pkill -x -u "$(id -un)" cosmic-greeter || true
        echo "Installed the lock screen."
    else
        rm -f "$dest.new"
        echo "The lock screen doesn't run on this system; keeping the stock one." >&2
    fi
fi

echo
echo "Done. Log out and back in to finish (the notifications icon needs a fresh session)."
echo "To skip the login password after unlocking the disk, run ./scripts/autologin.sh"
