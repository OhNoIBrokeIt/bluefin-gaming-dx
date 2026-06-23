import Adw from 'gi://Adw';
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

function addMonitorDirectory(group, settings, monitorIndex) {
    const key = String(monitorIndex);
    let refreshing = false;
    const row = new Adw.EntryRow({
        title: `Monitor ${monitorIndex} directory`,
    });

    const refresh = () => {
        const directories = settings.get_value('monitor-directories').deep_unpack();
        refreshing = true;
        row.text = directories[key] ?? '';
        refreshing = false;
    };

    row.connect('changed', () => {
        if (refreshing)
            return;

        const directories = settings.get_value('monitor-directories').deep_unpack();
        const path = row.text.trim();

        if (path)
            directories[key] = path;
        else
            delete directories[key];

        settings.set_value('monitor-directories', new GLib.Variant('a{ss}', directories));
    });
    settings.connect('changed::monitor-directories', refresh);

    refresh();
    group.add(row);
}

export default class OhNoWallpaperPrefs extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();
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
        addMonitorDirectory(directoriesGroup, settings, 0);
        addMonitorDirectory(directoriesGroup, settings, 1);
        addMonitorDirectory(directoriesGroup, settings, 2);
        addMonitorDirectory(directoriesGroup, settings, 3);
        addEntry(directoriesGroup, settings, 'cache-directory', 'Generated image cache directory', 'Leave empty to use the default user cache directory.');

        const wallhavenGroup = new Adw.PreferencesGroup({
            title: 'Wallhaven',
        });
        page.add(wallhavenGroup);
        addSwitch(wallhavenGroup, settings, 'wallhaven-enabled', 'Download from Wallhaven');
        addEntry(wallhavenGroup, settings, 'wallhaven-directory', 'Download directory');
        addEntry(wallhavenGroup, settings, 'wallhaven-query', 'Search query');
        addEntry(wallhavenGroup, settings, 'wallhaven-atleast', 'Minimum resolution');
        addEntry(wallhavenGroup, settings, 'wallhaven-sorting', 'Sorting');
        addEntry(wallhavenGroup, settings, 'wallhaven-categories', 'Categories');
        addEntry(wallhavenGroup, settings, 'wallhaven-purity', 'Purity');
        addEntry(wallhavenGroup, settings, 'wallhaven-api-key', 'API key');
        addSpin(wallhavenGroup, settings, 'wallhaven-refresh-minutes', 'Download interval', 0, 1440, 10, 'Minutes. Set to 0 to disable automatic downloads.');
        addButton(wallhavenGroup, 'Download now', 'Fetch one image into the Wallhaven directory.', 'folder-download-symbolic', () => {
            settings.set_int('wallhaven-fetch-token', settings.get_int('wallhaven-fetch-token') + 1);
        });

        window.add(page);
    }
}
