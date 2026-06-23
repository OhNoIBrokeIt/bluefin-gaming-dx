import Adw from 'gi://Adw';
import Gdk from 'gi://Gdk?version=4.0';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Gtk from 'gi://Gtk';

import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

function addSwitch(group, settings, key, title, subtitle = null) {
    const row = new Adw.SwitchRow({title, subtitle});
    settings.bind(key, row, 'active', Gio.SettingsBindFlags.DEFAULT);
    group.add(row);
}

function addEntry(group, settings, key, title, subtitle = null) {
    const row = new Adw.EntryRow({title});
    if (subtitle)
        row.set_tooltip_text(subtitle);

    settings.bind(key, row, 'text', Gio.SettingsBindFlags.DEFAULT);
    group.add(row);
}

function addMappedEntry(group, settings, mapKey, monitor, title, subtitle = null) {
    const primaryKey = monitor.connector || String(monitor.index);
    const fallbackKey = String(monitor.index);
    let refreshing = false;
    const row = new Adw.EntryRow({
        title: `${monitor.label} ${title}`,
    });

    if (subtitle)
        row.set_tooltip_text(subtitle);

    const refresh = () => {
        const values = settings.get_value(mapKey).deep_unpack();
        refreshing = true;
        row.text = values[primaryKey] ?? values[fallbackKey] ?? '';
        refreshing = false;
    };

    row.connect('changed', () => {
        if (refreshing)
            return;

        const values = settings.get_value(mapKey).deep_unpack();
        const value = row.text.trim();

        if (value)
            values[primaryKey] = value;
        else
            delete values[primaryKey];

        if (primaryKey !== fallbackKey)
            delete values[fallbackKey];

        settings.set_value(mapKey, new GLib.Variant('a{ss}', values));
    });
    settings.connect(`changed::${mapKey}`, refresh);

    refresh();
    group.add(row);
}

function addSpin(group, settings, key, title, lower, upper, step, subtitle = null) {
    const adjustment = new Gtk.Adjustment({
        lower,
        upper,
        step_increment: step,
        page_increment: step * 5,
    });
    const spin = new Gtk.SpinButton({
        adjustment,
        numeric: true,
        valign: Gtk.Align.CENTER,
    });
    const row = new Adw.ActionRow({
        title,
        subtitle,
        activatable_widget: spin,
    });

    spin.set_value(settings.get_int(key));
    spin.connect('value-changed', () => {
        settings.set_int(key, spin.get_value_as_int());
    });
    settings.connect(`changed::${key}`, () => {
        if (spin.get_value_as_int() !== settings.get_int(key))
            spin.set_value(settings.get_int(key));
    });

    row.add_suffix(spin);
    group.add(row);
}

function addButton(group, title, subtitle, iconName, callback) {
    const button = new Gtk.Button({
        icon_name: iconName,
        valign: Gtk.Align.CENTER,
    });
    const row = new Adw.ActionRow({
        title,
        subtitle,
        activatable_widget: button,
    });

    button.connect('clicked', callback);
    row.add_suffix(button);
    group.add(row);
}

function monitorLabel(monitor, index) {
    const connector = monitor.get_connector?.() || String(index);
    const description = monitor.get_description?.();
    const manufacturer = monitor.get_manufacturer?.();
    const model = monitor.get_model?.();
    const name = description || [manufacturer, model].filter(Boolean).join(' ');

    return {
        index,
        connector,
        label: [connector, name].filter(Boolean).join(' - '),
    };
}

function currentMonitors() {
    const monitors = [];

    try {
        const display = Gdk.Display.get_default();
        const model = display?.get_monitors();
        const count = model?.get_n_items?.() ?? 0;

        for (let index = 0; index < count; index++)
            monitors.push(monitorLabel(model.get_item(index), index));
    } catch (error) {
        console.warn(`Oh No Wallpaper failed to read monitor names: ${error}`);
    }

    if (monitors.length > 0)
        return monitors;

    return [0, 1, 2, 3].map(index => ({
        index,
        connector: String(index),
        label: `Monitor ${index}`,
    }));
}

export default class OhNoWallpaperPrefs extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();
        const monitors = currentMonitors();
        const page = new Adw.PreferencesPage({
            title: 'Wallpaper',
            icon_name: 'preferences-desktop-wallpaper-symbolic',
        });

        const behaviorGroup = new Adw.PreferencesGroup({
            title: 'Behavior',
        });
        page.add(behaviorGroup);
        addSwitch(behaviorGroup, settings, 'enabled', 'Manage wallpaper');
        addSwitch(behaviorGroup, settings, 'recursive', 'Scan directories recursively');
        addSpin(behaviorGroup, settings, 'refresh-minutes', 'Refresh interval', 0, 1440, 5, 'Minutes. Set to 0 to disable automatic refresh.');
        addButton(behaviorGroup, 'Shuffle now', 'Generate a new spanned wallpaper from the configured directories.', 'view-refresh-symbolic', () => {
            settings.set_int('shuffle-token', settings.get_int('shuffle-token') + 1);
        });

        const directoriesGroup = new Adw.PreferencesGroup({
            title: 'Directories',
        });
        page.add(directoriesGroup);
        addEntry(directoriesGroup, settings, 'default-directory', 'Default directory', 'Fallback directory for monitors without a dedicated path.');
        for (const monitor of monitors)
            addMappedEntry(directoriesGroup, settings, 'monitor-directories', monitor, 'local directory');
        addEntry(directoriesGroup, settings, 'cache-directory', 'Generated image cache directory', 'Leave empty to use the default user cache directory.');

        const wallhavenGroup = new Adw.PreferencesGroup({
            title: 'Wallhaven',
        });
        page.add(wallhavenGroup);
        addSwitch(wallhavenGroup, settings, 'wallhaven-enabled', 'Download from Wallhaven');
        addEntry(wallhavenGroup, settings, 'wallhaven-directory', 'Default download directory', 'Fallback used when no per-monitor Wallhaven directory is set.');
        addEntry(wallhavenGroup, settings, 'wallhaven-query', 'Default search query', 'Fallback used when no per-monitor Wallhaven query is set.');
        addEntry(wallhavenGroup, settings, 'wallhaven-atleast', 'Default minimum resolution', 'Fallback used when no per-monitor Wallhaven minimum is set.');
        for (const monitor of monitors) {
            addMappedEntry(wallhavenGroup, settings, 'wallhaven-directories', monitor, 'Wallhaven directory');
            addMappedEntry(wallhavenGroup, settings, 'wallhaven-queries', monitor, 'Wallhaven query');
            addMappedEntry(wallhavenGroup, settings, 'wallhaven-atleasts', monitor, 'Wallhaven minimum resolution');
        }
        addEntry(wallhavenGroup, settings, 'wallhaven-sorting', 'Sorting');
        addEntry(wallhavenGroup, settings, 'wallhaven-categories', 'Categories');
        addEntry(wallhavenGroup, settings, 'wallhaven-purity', 'Purity');
        addEntry(wallhavenGroup, settings, 'wallhaven-api-key', 'API key');
        addSpin(wallhavenGroup, settings, 'wallhaven-refresh-minutes', 'Download interval', 0, 1440, 10, 'Minutes. Set to 0 to disable automatic downloads.');
        addButton(wallhavenGroup, 'Download now', 'Fetch one image for each configured Wallhaven monitor directory.', 'folder-download-symbolic', () => {
            settings.set_int('wallhaven-fetch-token', settings.get_int('wallhaven-fetch-token') + 1);
        });

        window.add(page);
    }
}
