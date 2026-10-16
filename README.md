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
- **Clipboard history** on `Super+V`: your last 25 copies (text and screenshots), pin the ones you want to keep
- **Search** finds apps, settings pages and folders, grouped so you can tell them apart; `Ctrl+Super+F` opens it on the monitor you're working on
- **Lock screen** with just your picture, name and password on a card, over your wallpaper with drifting sparks (matches [driftpaper](https://github.com/Casper-RS/driftpaper) if you use it)
- **Fits laptops:** on screens under 1500px wide the search box shrinks to an icon, and window previews and the lock screen card stay within the screen
- Shortcuts: `Ctrl+Super+F` search, `Super+V` clipboard history, `Super+I` Settings, `Super+L` lock, `Super+Shift+L` log out

## Screenshots

### Taskbar & Start button
<img width="258" height="59" alt="image" src="https://github.com/user-attachments/assets/11876eab-23ec-4859-a461-6aaf391b1cb6" />

<hr>

### Window previews on hover
<img width="2557" height="373" alt="Window previews on hover" src="https://github.com/user-attachments/assets/fdae5b7a-08b2-4b1a-8403-1a8fb27afc81" />

<hr>

### Start menu
<img width="387" height="445" alt="image" src="https://github.com/user-attachments/assets/0da5ec37-ef43-4f67-b963-5f7e61bd936e" />

> Note: You can swap between pinned and most used apps on the top.

<hr>

### All apps
<img width="387" height="445" alt="image" src="https://github.com/user-attachments/assets/defd89b9-de70-4621-af2e-2f4550a07c31" />

<hr>

### Search
<img width="444" height="620" alt="image" src="https://github.com/user-attachments/assets/8d27dace-7adc-46b3-82ea-728ca057aca1" />
<img width="439" height="350" alt="image" src="https://github.com/user-attachments/assets/a6b29457-14d6-41bf-b8cf-abcbe4bf296c" />


## Using it

- **Pin tiles:** right-click an app in Start (Most used tiles or All apps) or in the searchbar to pin or unpin it.
- **Switch tile view:** use the dropdown above the tiles to pick Pinned or Most used.
- **Search:** click the search box or press `Ctrl+Super+F` and type. Results are grouped into Apps, Settings and Folders; Enter opens the selected one (a settings page opens in COSMIC Settings, a folder in your file manager). Use the arrow keys to move, Esc or a click outside to close.
- **Clipboard history:** press `Super+V`, then click an item (or use the arrow keys and Enter) to paste it into the window you were in. Pin items to keep them after logging out; Delete removes the selected item. Copies that password managers mark as secret are never recorded, and the rest is kept in memory only.

## Install

```sh
git clone https://github.com/Casper-RS/PopOS_Windows_Like_UI.git
cd PopOS_Windows_Like_UI
./scripts/install.sh
```

Then log out and back in.

### Optional: only type a password once per boot

If your disk is encrypted, run this to log in automatically after the disk password:

```sh
./scripts/autologin.sh
```

It asks for your password once (sudo), then opens a dialog to remove the keyring password: type your current password and leave the new one empty, so Chrome and other apps stop asking for it. It refuses to run if the disk isn't encrypted. Undo with `./scripts/autologin.sh --undo`.

To build from source instead of downloading the release, run `./scripts/install.sh --build`.

The lock screen is a patched copy of COSMIC's `cosmic-greeter` installed in `~/.local/bin` (your login screen stays as it is). It's made for COSMIC 1.10 and skipped on other versions; skip it yourself with `NO_LOCKSCREEN=1 ./scripts/install.sh`. If it ever won't unlock, press `Ctrl+Alt+F3`, log in and run `rm ~/.local/bin/cosmic-greeter; pkill -x cosmic-greeter; loginctl unlock-sessions`.

## Uninstall

```sh
./scripts/uninstall.sh
```

This restores your previous panel and shortcuts.

## Credits

- Built on [COSMIC applets](https://github.com/pop-os/cosmic-applets) by System76
- [Status Hub](https://github.com/marcelogomes90/cosmic-ext-applet-status-hub) by marcelogomes90
- [System Monitor](https://github.com/D-Brox/cosmic-ext-applet-system-monitor) by D-Brox
- [COSMIC Greeter](https://github.com/pop-os/cosmic-greeter) by System76 (lock screen)

Licensed under GPL-3.0.
