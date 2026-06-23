# Scroller Extension Test Notes

Date: 2026-06-23

## Current Blocker

The running GNOME Shell session is pinned to the system-installed scroller copy:

```text
ohno-scroller@ohnoibrokeit.dev
Path: /usr/share/gnome-shell/extensions/ohno-scroller@ohnoibrokeit.dev
Enabled: No
State: ERROR
```

The error is the same extension-local schema issue already fixed in
`build_files/build.sh` for future image builds:

```text
GLib.FileError: Failed to open file "/usr/share/gnome-shell/extensions/ohno-scroller@ohnoibrokeit.dev/schemas/gschemas.compiled": open() failed: No such file or directory
```

## Live-Test State

A user-local compiled copy is ready:

```text
/var/home/ohnoibrokeit/.local/share/gnome-shell/extensions/ohno-scroller@ohnoibrokeit.dev
```

It contains:

```text
schemas/dev.ohnoibrokeit.gnome-shell.extensions.ohno-scroller.gschema.xml
schemas/gschemas.compiled
```

The temporary `ohno-scroller-live-test@ohnoibrokeit.dev` directory and zip were
removed, so the next session should only see the real UUID.

## After Logout/Login

Run:

```bash
gnome-extensions info ohno-scroller@ohnoibrokeit.dev
gnome-extensions enable ohno-scroller@ohnoibrokeit.dev
sleep 2
gnome-extensions info ohno-scroller@ohnoibrokeit.dev
gnome-extensions prefs ohno-scroller@ohnoibrokeit.dev
journalctl --user -b --since "5 minutes ago" --no-pager | rg "ohno-scroller|Oh No Scroller|GLib.FileError|JS ERROR|TypeError|SyntaxError"
```

Expected startup result:

```text
Path: /var/home/ohnoibrokeit/.local/share/gnome-shell/extensions/ohno-scroller@ohnoibrokeit.dev
Enabled: Yes
State: ACTIVE
```

## Manual Tiling Test

Do not run Pop Shell and `ohno-scroller` at the same time.

1. Confirm Pop Shell is disabled:

   ```bash
   gnome-extensions info pop-shell@system76.com
   ```

2. Open several normal resizable windows on one workspace, preferably terminals.
3. Test:
   - New windows enter the active column.
   - `<Super><Shift>Return` moves the focused window to a new column.
   - `<Super>h` and `<Super>l` focus adjacent columns.
   - `<Super><Shift>h` and `<Super><Shift>l` move the focused window between columns.
   - `<Super><Shift>y` retile works after moving windows manually.
   - Fullscreen/non-resizable windows are ignored.
4. Check logs:

   ```bash
   journalctl --user -b --since "10 minutes ago" --no-pager | rg "ohno-scroller|Oh No Scroller|JS ERROR|TypeError|SyntaxError"
   ```

## Known Publish Follow-Up

Before extracting this into its own public extension repo, apply the same
publish-readiness checklist captured in `docs/gnome-extension-publish-notes.md`.
