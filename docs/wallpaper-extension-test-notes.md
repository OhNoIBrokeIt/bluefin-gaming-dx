# Wallpaper Extension Test Notes

Date: 2026-06-22

## Current Finding

After reboot, GNOME sees `ohno-wallpaper@ohnoibrokeit.dev`, but the system-installed copy is broken:

```text
Enabled: No
State: ERROR
Path: /usr/share/gnome-shell/extensions/ohno-wallpaper@ohnoibrokeit.dev
```

The GNOME Shell journal error is:

```text
GLib.FileError: Failed to open file "/usr/share/gnome-shell/extensions/ohno-wallpaper@ohnoibrokeit.dev/schemas/gschemas.compiled": open() failed: No such file or directory
```

`ohno-scroller@ohnoibrokeit.dev` has the same missing `schemas/gschemas.compiled` issue.

## Repo Fix Already Made

`build_files/build.sh` now runs `glib-compile-schemas` inside each custom extension's own `schemas/` directory after copying it into `/usr/share/gnome-shell/extensions`.

Verified:

```bash
bash -n build_files/build.sh
git diff --check
glib-compile-schemas --strict
```

The only repo change should be:

```text
M build_files/build.sh
```

## Live Session State

The current GNOME session stayed pinned to the broken system extension path. Installing a user-local copy did not make the running shell rescan extension directories.

A user-local compiled copy exists here:

```text
/var/home/ohnoibrokeit/.local/share/gnome-shell/extensions/ohno-wallpaper@ohnoibrokeit.dev
```

It contains:

```text
schemas/dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper.gschema.xml
schemas/gschemas.compiled
```

The temporary live-test UUID was removed.

## Wallpaper Settings Set For Retest

Monitor connectors from Mutter:

```text
DP-1 = MSI MPG491CX OLED / ultrawide
DP-2 = IOC 32M2V / 4K
```

Configured extension settings:

```bash
gsettings get dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper monitor-directories
```

Expected value:

```text
{'DP-1': '/var/home/ohnoibrokeit/Pictures/Wallpapers/ultrawide', 'DP-2': '/var/home/ohnoibrokeit/Pictures/Wallpapers/4k'}
```

Wallhaven was disabled and refresh interval was set to `0` for a controlled local-only test.

## After Logout/Login

Run:

```bash
gnome-extensions info ohno-wallpaper@ohnoibrokeit.dev
gnome-extensions enable ohno-wallpaper@ohnoibrokeit.dev
sleep 2
gnome-extensions info ohno-wallpaper@ohnoibrokeit.dev
ls -la ~/.cache/ohno-wallpaper
gsettings get org.gnome.desktop.background picture-uri
gsettings get org.gnome.desktop.background picture-options
journalctl --user -b --since "5 minutes ago" --no-pager | rg "ohno-wallpaper|GLib.FileError|JS ERROR"
```

Success criteria:

```text
State: ENABLED
~/.cache/ohno-wallpaper/current-*.png exists
org.gnome.desktop.background picture-uri points at that generated PNG
picture-options is 'spanned'
```

If the shell still loads `/usr/share/...` and errors, rebuild/rebase into an image containing the patched `build_files/build.sh`.

## Post-Login Retest Result

Retested after logging back in on 2026-06-22.

`ohno-wallpaper@ohnoibrokeit.dev` is now loaded from the user-local compiled copy:

```text
Path: /var/home/ohnoibrokeit/.local/share/gnome-shell/extensions/ohno-wallpaper@ohnoibrokeit.dev
Enabled: Yes
State: ACTIVE
```

The wallpaper generation path passed:

```text
/var/home/ohnoibrokeit/.cache/ohno-wallpaper/current-1782181195717.png
PNG image data, 5120 x 3168, 8-bit/color RGBA, non-interlaced
```

GNOME background settings were updated:

```text
picture-uri: 'file:///var/home/ohnoibrokeit/.cache/ohno-wallpaper/current-1782181195717.png'
picture-uri-dark: 'file:///var/home/ohnoibrokeit/.cache/ohno-wallpaper/current-1782181195717.png'
picture-options: 'spanned'
```

Controlled-test settings remained in place:

```text
monitor-directories: {'DP-1': '/var/home/ohnoibrokeit/Pictures/Wallpapers/ultrawide', 'DP-2': '/var/home/ohnoibrokeit/Pictures/Wallpapers/4k'}
wallhaven-enabled: false
refresh-minutes: 0
```

Filtered user journal after enabling showed no matching entries:

```text
journalctl --user -b --since '2026-06-22 22:19:30' --no-pager -g 'ohno-wallpaper|GLib.FileError|JS ERROR'
-- No entries --
```

The system-installed extension directory still lacks its local `schemas/gschemas.compiled`, so the baked image still needs the `build_files/build.sh` fix to be rebuilt/rebased:

```text
/usr/share/gnome-shell/extensions/ohno-wallpaper@ohnoibrokeit.dev/schemas/
dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper.gschema.xml
```
