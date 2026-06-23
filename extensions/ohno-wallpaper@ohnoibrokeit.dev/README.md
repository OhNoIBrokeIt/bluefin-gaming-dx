# Oh No Wallpaper

Experimental GNOME wallpaper manager for multi-monitor setups.

The extension builds a single spanned wallpaper image from per-monitor source
directories, then points GNOME at that generated image. This avoids depending
on private GNOME Shell background actor internals while still giving each
monitor its own wallpaper source.

Configure it with `gsettings`:

```bash
gnome-extensions prefs ohno-wallpaper@ohnoibrokeit.dev
```

Or configure it directly with `gsettings`:

```bash
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper default-directory "$HOME/Pictures/Wallpapers/default"
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper monitor-directories "{'DP-1': '$HOME/Pictures/Wallpapers/ultrawide', 'HDMI-1': '$HOME/Pictures/Wallpapers/vertical'}"
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper refresh-minutes 30
```

Wallhaven can be enabled as a per-monitor feeder. `wallhaven-directory`,
`wallhaven-query`, and `wallhaven-atleast` are defaults. The map settings
override those defaults for specific monitor connectors:

```bash
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-enabled true
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-directories "{'DP-1': '$HOME/Pictures/Wallpapers/wallhaven/ultrawide', 'HDMI-1': '$HOME/Pictures/Wallpapers/wallhaven/vertical'}"
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-queries "{'DP-1': 'mountains 5120x1440', 'HDMI-1': 'forest portrait'}"
gsettings set dev.ohnoibrokeit.gnome-shell.extensions.ohno-wallpaper wallhaven-atleasts "{'DP-1': '5120x1440', 'HDMI-1': '2160x3840'}"
```

Monitor keys prefer connector names from Mutter, such as `DP-1` or `HDMI-1`.
Numeric keys like `0` and `1` work as fallbacks.
