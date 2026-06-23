import GdkPixbuf from 'gi://GdkPixbuf';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';

import {Extension as ExtensionBase} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const BACKGROUND_SCHEMA = 'org.gnome.desktop.background';
const WALLHAVEN_SEARCH_URL = 'https://wallhaven.cc/api/v1/search';
const MAX_SCAN_DEPTH = 6;
const MAX_CACHE_FILES = 8;

export default class OhNoWallpaperExtension extends ExtensionBase {
    enable() {
        this._settings = this.getSettings();
        this._backgroundSettings = new Gio.Settings({schema_id: BACKGROUND_SCHEMA});
        this._session = new Soup.Session();
        this._cancellable = new Gio.Cancellable();
        this._signals = [];
        this._timeoutIds = [];
        this._refreshQueued = false;
        this._wallhavenDownloadInProgress = false;

        this._connect(Main.layoutManager, 'monitors-changed', () => this._queueRefresh());
        this._connect(this._settings, 'changed', () => {
            this._scheduleTimers();
            this._queueRefresh();
        });

        this._scheduleTimers();
        this._fetchWallhaven();
        this._queueRefresh();
    }

    disable() {
        this._cancellable?.cancel();

        for (const id of this._timeoutIds)
            GLib.source_remove(id);

        for (const [object, id] of this._signals)
            object.disconnect(id);

        this._timeoutIds = [];
        this._signals = [];
        this._settings = null;
        this._backgroundSettings = null;
        this._session = null;
        this._cancellable = null;
    }

    _connect(object, signal, callback) {
        this._signals.push([object, object.connect(signal, callback)]);
    }

    _scheduleTimers() {
        for (const id of this._timeoutIds)
            GLib.source_remove(id);

        this._timeoutIds = [];

        const refreshMinutes = this._settings.get_int('refresh-minutes');
        if (refreshMinutes > 0) {
            this._timeoutIds.push(GLib.timeout_add_seconds(
                GLib.PRIORITY_DEFAULT,
                refreshMinutes * 60,
                () => {
                    this._queueRefresh();
                    return GLib.SOURCE_CONTINUE;
                }
            ));
        }

        const wallhavenMinutes = this._settings.get_int('wallhaven-refresh-minutes');
        if (wallhavenMinutes > 0) {
            this._timeoutIds.push(GLib.timeout_add_seconds(
                GLib.PRIORITY_DEFAULT,
                wallhavenMinutes * 60,
                () => {
                    this._fetchWallhaven();
                    return GLib.SOURCE_CONTINUE;
                }
            ));
        }
    }

    _queueRefresh() {
        if (this._refreshQueued)
            return;

        this._refreshQueued = true;
        Promise.resolve().then(() => {
            this._refreshQueued = false;
            this._refresh();
        });
    }

    _refresh() {
        if (!this._settings.get_boolean('enabled'))
            return;

        const monitors = Main.layoutManager.monitors;
        if (!monitors?.length)
            return;

        try {
            const outputPath = this._compose(monitors);
            if (!outputPath)
                return;

            const uri = Gio.File.new_for_path(outputPath).get_uri();
            this._backgroundSettings.set_string('picture-options', 'spanned');
            this._backgroundSettings.set_string('picture-uri', uri);

            if (this._backgroundSettings.settings_schema.has_key('picture-uri-dark'))
                this._backgroundSettings.set_string('picture-uri-dark', uri);
        } catch (error) {
            logError(error, 'Oh No Wallpaper failed to compose wallpaper');
        }
    }

    _compose(monitors) {
        const bounds = this._monitorBounds(monitors);
        const canvas = GdkPixbuf.Pixbuf.new(
            GdkPixbuf.Colorspace.RGB,
            true,
            8,
            bounds.width,
            bounds.height
        );

        canvas.fill(0x000000ff);

        let applied = false;
        for (let index = 0; index < monitors.length; index++) {
            const monitor = monitors[index];
            const sourcePath = this._selectWallpaper(index);

            if (!sourcePath)
                continue;

            try {
                this._paintMonitor(canvas, sourcePath, monitor, bounds);
                applied = true;
            } catch (error) {
                logError(error, `Oh No Wallpaper failed to paint ${sourcePath}`);
            }
        }

        if (!applied)
            return null;

        const cacheDir = this._cacheDirectory();
        GLib.mkdir_with_parents(cacheDir, 0o755);

        const outputPath = GLib.build_filenamev([
            cacheDir,
            `current-${Date.now()}.png`,
        ]);

        canvas.savev(outputPath, 'png', [], []);
        this._pruneCache(cacheDir);

        return outputPath;
    }

    _monitorBounds(monitors) {
        const minX = Math.min(...monitors.map(monitor => monitor.x));
        const minY = Math.min(...monitors.map(monitor => monitor.y));
        const maxX = Math.max(...monitors.map(monitor => monitor.x + monitor.width));
        const maxY = Math.max(...monitors.map(monitor => monitor.y + monitor.height));

        return {
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY,
        };
    }

    _paintMonitor(canvas, sourcePath, monitor, bounds) {
        const source = GdkPixbuf.Pixbuf.new_from_file(sourcePath);
        const scale = Math.max(
            monitor.width / source.get_width(),
            monitor.height / source.get_height()
        );
        const scaledWidth = Math.max(1, Math.ceil(source.get_width() * scale));
        const scaledHeight = Math.max(1, Math.ceil(source.get_height() * scale));
        const scaled = source.scale_simple(scaledWidth, scaledHeight, GdkPixbuf.InterpType.HYPER);
        const cropX = Math.max(0, Math.floor((scaledWidth - monitor.width) / 2));
        const cropY = Math.max(0, Math.floor((scaledHeight - monitor.height) / 2));
        const targetX = monitor.x - bounds.x;
        const targetY = monitor.y - bounds.y;

        scaled.copy_area(
            cropX,
            cropY,
            monitor.width,
            monitor.height,
            canvas,
            targetX,
            targetY
        );
    }

    _selectWallpaper(monitorIndex) {
        const directory = this._directoryForMonitor(monitorIndex);
        if (!directory)
            return null;

        const images = this._listImages(directory, 0);
        if (images.length === 0)
            return null;

        return images[Math.floor(Math.random() * images.length)];
    }

    _directoryForMonitor(monitorIndex) {
        const directories = this._settings.get_value('monitor-directories').deep_unpack();
        const connector = this._monitorConnector(monitorIndex);
        const candidates = [
            connector,
            String(monitorIndex),
        ];

        for (const key of candidates) {
            if (key && directories[key])
                return this._expandPath(directories[key]);
        }

        const defaultDirectory = this._settings.get_string('default-directory');
        if (defaultDirectory)
            return this._expandPath(defaultDirectory);

        const wallhavenDirectory = this._settings.get_string('wallhaven-directory');
        if (this._settings.get_boolean('wallhaven-enabled') && wallhavenDirectory)
            return this._expandPath(wallhavenDirectory);

        return null;
    }

    _monitorConnector(monitorIndex) {
        try {
            if (global.display.get_monitor_connector)
                return global.display.get_monitor_connector(monitorIndex);
        } catch (error) {
            logError(error, 'Oh No Wallpaper failed to read monitor connector');
        }

        return null;
    }

    _listImages(directory, depth) {
        const path = this._expandPath(directory);
        const file = Gio.File.new_for_path(path);

        if (!file.query_exists(null))
            return [];

        const recursive = this._settings.get_boolean('recursive');
        const extensions = new Set(this._settings.get_strv('image-extensions').map(item => item.toLowerCase()));
        const images = [];

        try {
            const enumerator = file.enumerate_children(
                'standard::name,standard::type',
                Gio.FileQueryInfoFlags.NONE,
                null
            );

            let info;
            while ((info = enumerator.next_file(null)) !== null) {
                const name = info.get_name();
                const childPath = GLib.build_filenamev([path, name]);

                if (info.get_file_type() === Gio.FileType.DIRECTORY) {
                    if (recursive && depth < MAX_SCAN_DEPTH)
                        images.push(...this._listImages(childPath, depth + 1));
                    continue;
                }

                if (info.get_file_type() !== Gio.FileType.REGULAR)
                    continue;

                const lowerName = name.toLowerCase();
                if ([...extensions].some(extension => lowerName.endsWith(extension)))
                    images.push(childPath);
            }

            enumerator.close(null);
        } catch (error) {
            logError(error, `Oh No Wallpaper failed to scan ${path}`);
        }

        return images;
    }

    _cacheDirectory() {
        const configured = this._settings.get_string('cache-directory');
        if (configured)
            return this._expandPath(configured);

        return GLib.build_filenamev([GLib.get_user_cache_dir(), 'ohno-wallpaper']);
    }

    _pruneCache(cacheDir) {
        const file = Gio.File.new_for_path(cacheDir);
        const entries = [];

        try {
            const enumerator = file.enumerate_children(
                'standard::name,time::modified',
                Gio.FileQueryInfoFlags.NONE,
                null
            );

            let info;
            while ((info = enumerator.next_file(null)) !== null) {
                const name = info.get_name();
                if (name.startsWith('current-') && name.endsWith('.png')) {
                    entries.push({
                        path: GLib.build_filenamev([cacheDir, name]),
                        modified: info.get_attribute_uint64('time::modified'),
                    });
                }
            }

            enumerator.close(null);
        } catch (error) {
            logError(error, `Oh No Wallpaper failed to scan cache ${cacheDir}`);
            return;
        }

        entries.sort((left, right) => right.modified - left.modified);
        for (const entry of entries.slice(MAX_CACHE_FILES)) {
            try {
                Gio.File.new_for_path(entry.path).delete(null);
            } catch (error) {
                logError(error, `Oh No Wallpaper failed to prune ${entry.path}`);
            }
        }
    }

    _fetchWallhaven() {
        if (!this._settings?.get_boolean('wallhaven-enabled'))
            return;

        if (this._wallhavenDownloadInProgress)
            return;

        const directory = this._settings.get_string('wallhaven-directory');
        if (!directory)
            return;

        const url = this._wallhavenSearchUrl();
        const message = Soup.Message.new('GET', url);
        const apiKey = this._settings.get_string('wallhaven-api-key');

        if (apiKey)
            message.request_headers.append('X-API-Key', apiKey);

        this._wallhavenDownloadInProgress = true;
        this._session.send_and_read_async(
            message,
            GLib.PRIORITY_DEFAULT,
            this._cancellable,
            (session, result) => {
                try {
                    const bytes = session.send_and_read_finish(result);
                    const payload = JSON.parse(new TextDecoder().decode(bytes.toArray()));
                    const items = payload.data ?? [];

                    if (items.length === 0)
                        return;

                    const item = items[Math.floor(Math.random() * items.length)];
                    if (item?.path)
                        this._downloadWallhavenImage(item.path);
                } catch (error) {
                    if (!this._cancellable?.is_cancelled())
                        logError(error, 'Oh No Wallpaper failed to query Wallhaven');
                    this._wallhavenDownloadInProgress = false;
                }
            }
        );
    }

    _downloadWallhavenImage(url) {
        const message = Soup.Message.new('GET', url);

        this._session.send_and_read_async(
            message,
            GLib.PRIORITY_DEFAULT,
            this._cancellable,
            (session, result) => {
                try {
                    const bytes = session.send_and_read_finish(result);
                    const directory = this._expandPath(this._settings.get_string('wallhaven-directory'));
                    const basename = url.split('/').pop() || `${Date.now()}.jpg`;
                    const targetPath = GLib.build_filenamev([directory, `${Date.now()}-${basename}`]);
                    const file = Gio.File.new_for_path(targetPath);

                    GLib.mkdir_with_parents(directory, 0o755);
                    file.replace_contents_bytes_async(
                        bytes,
                        null,
                        false,
                        Gio.FileCreateFlags.REPLACE_DESTINATION,
                        this._cancellable,
                        (targetFile, replaceResult) => {
                            try {
                                targetFile.replace_contents_finish(replaceResult);
                                this._queueRefresh();
                            } catch (error) {
                                if (!this._cancellable?.is_cancelled())
                                    logError(error, `Oh No Wallpaper failed to save ${targetPath}`);
                            } finally {
                                this._wallhavenDownloadInProgress = false;
                            }
                        }
                    );
                } catch (error) {
                    if (!this._cancellable?.is_cancelled())
                        logError(error, `Oh No Wallpaper failed to download ${url}`);
                    this._wallhavenDownloadInProgress = false;
                }
            }
        );
    }

    _wallhavenSearchUrl() {
        const params = {
            q: this._settings.get_string('wallhaven-query'),
            categories: this._settings.get_string('wallhaven-categories'),
            purity: this._settings.get_string('wallhaven-purity'),
            sorting: this._settings.get_string('wallhaven-sorting'),
            atleast: this._settings.get_string('wallhaven-atleast'),
            page: String(Math.max(1, Math.floor(Math.random() * 10) + 1)),
        };

        return `${WALLHAVEN_SEARCH_URL}?${Object.entries(params)
            .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
            .join('&')}`;
    }

    _expandPath(path) {
        if (!path)
            return path;

        if (path === '~')
            return GLib.get_home_dir();

        if (path.startsWith('~/'))
            return GLib.build_filenamev([GLib.get_home_dir(), path.slice(2)]);

        return path;
    }
}
