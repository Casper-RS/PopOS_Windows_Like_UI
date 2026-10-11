# PopOS Windows-Like UI

A Windows-style taskbar for the COSMIC desktop on Pop!_OS. It only changes the panel: your theme, light/dark mode and accent color stay as they are.

All applets come in one Flatpak.

## What you get

- One bottom taskbar, no top bar
- **Start menu** (Pop!_OS logo) in Windows 10 style: app tiles you can pin, a Most used view, an All apps list, and buttons for Task view, Settings, Lock/Log out and Power
- **Search box** that opens a search panel right above it, with app results and your recent apps
- **Taskbar** that shows window previews on hover, or the app name when it has no windows
- **Keyboard layout** shown in two lines, like `EN` / `US`
- Clean tray: Status Hub collects app tray icons, plus a system monitor, network, Bluetooth, battery (laptops only), sound, clock and notifications
- Shortcuts: `Super+I` Settings, `Super+L` lock, `Super+Shift+L` log out

## Screenshots

### Taskbar & Start button
<img width="2557" height="373" alt="Taskbar and Start button" src="https://github.com/user-attachments/assets/abb48336-b45c-4b23-ad51-89f38fc14cd7" />

### Window previews on hover
<img width="2557" height="373" alt="Window previews on hover" src="https://github.com/user-attachments/assets/fdae5b7a-08b2-4b1a-8403-1a8fb27afc81" />

### Start menu
<!-- Add images here -->

### All apps
<!-- Add images here -->

### Search
<!-- Add images here -->

### Tray and keyboard layout
<!-- Add images here -->

## Using it

- **Pin tiles:** right-click an app in Start (tiles or All apps) or in search to pin or unpin it.
- **Switch tile view:** use the dropdown above the tiles to pick Pinned or Most used.
- **Search:** click the search box and type. Use the arrow keys and Enter to launch, Esc to close.

## Install

```sh
git clone https://github.com/Casper-RS/PopOS_Windows_Like_UI.git
cd PopOS_Windows_Like_UI
./scripts/install.sh
```

Then log out and back in.

To build from source instead of downloading the release, run `./scripts/install.sh --build`.

## Uninstall

```sh
./scripts/uninstall.sh
```

This restores your previous panel and shortcuts.

## Credits

- Built on [COSMIC applets](https://github.com/pop-os/cosmic-applets) by System76
- [Status Hub](https://github.com/marcelogomes90/cosmic-ext-applet-status-hub) by marcelogomes90
- [System Monitor](https://github.com/D-Brox/cosmic-ext-applet-system-monitor) by D-Brox

Licensed under GPL-3.0.
