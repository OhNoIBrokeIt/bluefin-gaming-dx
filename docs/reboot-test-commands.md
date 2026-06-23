# Reboot Test Commands

Saved on 2026-06-23 after staging the GNOME image with native apps plus the custom GNOME tiler and wallpaper manager.

## Staged image

```text
ostree-image-signed:docker://ghcr.io/ohnoibrokeit/bluefin-gaming-dx:latest
digest: sha256:7f57d02afbe311d5c551d7179818291c07bf142f7e20f890185b7b35d93debca
commit: cc12c90 Add GNOME extension preferences UIs
```

Earlier extension commits:

- `4e774dc Add experimental GNOME scrolling tiler`
- `d87eb41 Add experimental GNOME wallpaper manager`
- `cc12c90 Add GNOME extension preferences UIs`

## Reboot

```bash
systemctl reboot
```

## Enable and test extensions

Do not run Pop Shell and `ohno-scroller` at the same time.

```bash
gnome-extensions enable ohno-scroller@ohnoibrokeit.dev
gnome-extensions prefs ohno-scroller@ohnoibrokeit.dev

gnome-extensions enable ohno-wallpaper@ohnoibrokeit.dev
gnome-extensions prefs ohno-wallpaper@ohnoibrokeit.dev
```

## Wallpaper defaults by command

The UI has fields for these, but direct commands are useful if the prefs window fails.

```bash
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper default-directory "$HOME/Pictures/Wallpapers/default"
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper monitor-directories "{'0': '$HOME/Pictures/Wallpapers/main', '1': '$HOME/Pictures/Wallpapers/side'}"
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper refresh-minutes 30
```

Wallhaven:

```bash
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-enabled true
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-query 'mountains'
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-directory "$HOME/Pictures/Wallpapers/wallhaven"
```

## Native app follow-up

After rebooting into the GNOME image, remove duplicate Flatpaks for apps now native:

```bash
flatpak uninstall com.slack.Slack com.protonvpn.www com.freerdp.FreeRDP
```

NordVPN may need group access:

```bash
sudo usermod -aG nordvpn "$USER"
```

Log out and back in after changing groups.

## What to verify

- `ghostty`, `kitty`, `steam`, `gamescope`, `slack`, `winboat`, `nordvpn`, and `protonvpn-app` exist.
- `gnome-extensions list` shows both `ohno-scroller@ohnoibrokeit.dev` and `ohno-wallpaper@ohnoibrokeit.dev`.
- `ohno-scroller` can tile terminals in scrolling columns.
- `ohno-wallpaper` can open prefs, set monitor directories, shuffle, and optionally download from Wallhaven.
