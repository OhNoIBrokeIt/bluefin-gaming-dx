# GNOME Extension Publish Notes

Date: 2026-06-23

The repo-native GNOME extensions are currently built into the image and tested
locally. Before publishing `ohno-wallpaper` or `ohno-scroller` on
extensions.gnome.org, do a dedicated packaging/review pass.

## Required Before Upload

- Move GSettings schema IDs and paths to the extensions.gnome.org expected
  namespace:
  - schema ID base: `org.gnome.shell.extensions`
  - schema path base: `/org/gnome/shell/extensions`
- Add a settings migration plan before renaming live schemas, otherwise existing
  local `dev.ohnoibrokeit...` settings will appear reset.
- Package only files needed by the extension:
  - `metadata.json`
  - `extension.js`
  - `prefs.js`, if preferences are included
  - `schemas/*.gschema.xml`
  - `schemas/gschemas.compiled`
  - any required extension-local assets
- Keep `Gtk`, `Gdk`, and `Adw` imports only in `prefs.js`; do not import them in
  `extension.js`.
- Keep `Clutter`, `Meta`, `St`, and `Shell` imports out of `prefs.js`.
- Confirm `disable()` disconnects signals, removes timers, cancels async work,
  and releases references.
- Make the extension description clear that Wallhaven downloads are optional
  network activity.

## Current Local Status

`ohno-wallpaper` has been validated locally with:

- real monitor names in prefs
- per-monitor local directories
- per-monitor Wallhaven directories, queries, and minimum resolutions
- active GNOME Shell load from the user-local extension path
- clean filtered Shell logs after load
