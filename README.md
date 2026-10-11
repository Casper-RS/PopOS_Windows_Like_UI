# PopOS Windows-Like UI

A Windows-style taskbar for the COSMIC desktop on Pop!_OS. It only changes the panel: your theme, light/dark mode and accent color stay as they are.

## What you get

- One bottom taskbar, no top bar
- **Start button** (Pop!_OS logo) with All apps, Task view, Settings, Lock, Log out and a Power submenu
- **Search box** that opens the launcher
- **App icons** that show window previews on hover, or the app name when it has no windows
- **Keyboard layout** shown in two lines, like `EN` / `US`
- Clean tray: Status Hub collects app tray icons, plus a system monitor, network, Bluetooth, battery (laptops only), sound, clock and notifications
- Shortcuts: `Super+I` Settings, `Super+L` lock, `Super+Shift+L` log out

All listed features are shown as below:

**Taskbar & Start Button**
<img width="2557" height="373" alt="image" src="https://github.com/user-attachments/assets/abb48336-b45c-4b23-ad51-89f38fc14cd7" />

**App hover window-preview**
<img width="2557" height="373" alt="image" src="https://github.com/user-attachments/assets/fdae5b7a-08b2-4b1a-8403-1a8fb27afc81" />

All applets come in one Flatpak.

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
- [System Monitor](https://github.com/D-Brox/cosmic-ext-applet-system-monitor) by D-Brox. Licensed under GPL-3.0.
