#!/usr/bin/python3 -u
"""Select TuneD profiles based on Steam games and KDE's lock state."""
import ctypes
import os
import re
import signal
import sys
import time
from pathlib import Path

from gi.repository import Gio, GLib

LOG = Path.home() / '.local/share/Steam/logs/gameprocess_log.txt'
SERVICE = 'net.hadess.PowerProfiles'
OBJECT = '/net/hadess/PowerProfiles'
SCREENSAVER = 'org.freedesktop.ScreenSaver'
SCREEN_OBJECT = '/org/freedesktop/ScreenSaver'
PROPERTIES = 'org.freedesktop.DBus.Properties'
TIMEOUT_MS = 5000


def app_key(value):
    # Steam logs 64-bit shortcut IDs on launch, but signed 32-bit IDs on removal.
    number = int(value)
    return ((number >> 32) if number > 0xFFFFFFFF else number) & 0xFFFFFFFF


ADD = re.compile(r'AppID (\d+) adding PID (\d+) as a tracked process')
EXIT = re.compile(r'AppID (\d+) no longer tracking PID (\d+), exit code')
REMOVE = re.compile(r'Remove (-?\d+) from running list')
CLIENT = re.compile(r'Client version: ')


def running(pid):
    try:
        return Path(f'/proc/{pid}/stat').read_text().rsplit(') ', 1)[1][0] != 'Z'
    except (FileNotFoundError, ProcessLookupError, PermissionError, IndexError):
        return False


class Monitor:
    def __init__(self):
        self.games = {}
        self.conn = None
        self.cookie = None
        self.next_retry = 0
        self.stream = None
        self.identity = None
        self.session = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.locked = None
        self.pid_watches = {}
        self.steam_pid = None
        self.retry_sources = {}

    def forget_pid(self, pid):
        entry = self.pid_watches.pop(pid, None)
        if entry is not None:
            fd, source = entry
            GLib.source_remove(source)
            os.close(fd)

    def watch_pid(self, pid):
        if pid in self.pid_watches:
            return True
        try:
            fd = os.pidfd_open(pid, 0)
        except ProcessLookupError:
            return False
        except OSError as exc:
            print(f'Cannot watch PID {pid}: {exc}', file=sys.stderr, flush=True)
            raise
        channel = GLib.IOChannel.unix_new(fd)
        source = GLib.io_add_watch(
            channel, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR | GLib.IO_NVAL,
            lambda unused_channel, condition: self.pid_exited(pid),
        )
        self.pid_watches[pid] = (fd, source)
        return True

    def pid_exited(self, pid):
        # GLib automatically removes this source after returning False.
        entry = self.pid_watches.pop(pid, None)
        if entry is not None:
            os.close(entry[0])
        if pid == self.steam_pid:
            self.steam_pid = None
            self.games.clear()
            print('Steam exited', flush=True)
        else:
            for key, pids in list(self.games.items()):
                pids.discard(pid)
                if not pids:
                    self.games.pop(key)
        self.reconcile_watches()
        self.sync()
        return GLib.SOURCE_REMOVE

    def reconcile_watches(self):
        target = set().union(*self.games.values()) if self.games else set()
        if self.steam_pid is not None:
            target.add(self.steam_pid)
        for pid in list(self.pid_watches):
            if pid not in target:
                self.forget_pid(pid)
        for pid in target - self.pid_watches.keys():
            if not self.watch_pid(pid):
                if pid == self.steam_pid:
                    self.steam_pid = None
                    self.games.clear()
                else:
                    for key, pids in list(self.games.items()):
                        pids.discard(pid)
                        if not pids:
                            self.games.pop(key)

    def detect_steam(self):
        # Only scan /proc at startup or when a log event arrives without a
        # currently watched Steam process; never from a repeating timer.
        if self.steam_pid is not None:
            return
        for directory in Path('/proc').iterdir():
            if directory.name.isdigit():
                try:
                    if (directory / 'comm').read_text().strip() == 'steam' and running(directory.name):
                        pid = int(directory.name)
                        if self.watch_pid(pid):
                            self.steam_pid = pid
                            return
                except (OSError, UnicodeError):
                    pass

    def process(self, line):
        if CLIENT.search(line):
            self.games.clear()
            return
        m = ADD.search(line)
        if m:
            self.games.setdefault(app_key(m[1]), set()).add(int(m[2]))
            return
        m = EXIT.search(line)
        if m:
            key, pid = app_key(m[1]), int(m[2])
            pids = self.games.get(key)
            if pids is not None:
                pids.discard(pid)
                if not pids:
                    del self.games[key]
            return
        # Steam can emit the wrong AppID in a running-list removal event
        # when multiple games overlap. Only per-AppID PID events (and pidfds)
        # determine whether a game is still running.
        if REMOVE.search(line):
            return

    def close_stream(self):
        if self.stream:
            self.stream.close()
        self.stream = None
        self.identity = None

    def load(self):
        try:
            st = LOG.stat()
        except FileNotFoundError:
            self.close_stream()
            self.games.clear()
            return
        if self.stream is None or self.identity != (st.st_dev, st.st_ino) or st.st_size < self.stream.tell():
            self.close_stream()
            self.games.clear()
            self.stream = LOG.open('rb')
            self.identity = (st.st_dev, st.st_ino)
            initial = True
        else:
            initial = False
        while True:
            pos = self.stream.tell()
            line = self.stream.readline()
            if not line:
                break
            if not line.endswith(b'\n'):
                self.stream.seek(pos)
                break
            self.process(line.decode('utf-8', errors='replace'))
        if initial:
            self.games = {
                key: {pid for pid in pids if running(pid)}
                for key, pids in self.games.items()
            }
            self.games = {key: pids for key, pids in self.games.items() if pids}

    def call(self, method, params, result_type=None):
        return self.conn.call_sync(
            SERVICE, OBJECT, SERVICE, method, params, result_type,
            Gio.DBusCallFlags.NONE, TIMEOUT_MS, None,
        )

    def connect_system(self):
        if self.conn is None or self.conn.is_closed():
            address = Gio.dbus_address_get_for_bus_sync(Gio.BusType.SYSTEM, None)
            self.conn = Gio.DBusConnection.new_for_address_sync(
                address,
                Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT |
                Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
                None, None,
            )
            self.cookie = None

    def screen_locked(self):
        result = self.session.call_sync(
            SCREENSAVER, SCREEN_OBJECT, SCREENSAVER, 'GetActive',
            None, GLib.VariantType.new('(b)'),
            Gio.DBusCallFlags.NONE, TIMEOUT_MS, None,
        )
        return result.unpack()[0]

    def get_profile(self):
        result = self.conn.call_sync(
            SERVICE, OBJECT, PROPERTIES, 'Get',
            GLib.Variant('(ss)', (SERVICE, 'ActiveProfile')),
            GLib.VariantType.new('(v)'),
            Gio.DBusCallFlags.NONE, TIMEOUT_MS, None,
        )
        return result.unpack()[0]

    def set_profile(self, profile):
        self.conn.call_sync(
            SERVICE, OBJECT, PROPERTIES, 'Set',
            GLib.Variant('(ssv)', (SERVICE, 'ActiveProfile', GLib.Variant('s', profile))),
            None, Gio.DBusCallFlags.NONE, TIMEOUT_MS, None,
        )
        print(f'Power profile set to {profile}', flush=True)

    def schedule_retry(self, name, callback, seconds=31):
        if name in self.retry_sources:
            return
        def retry():
            self.retry_sources.pop(name, None)
            callback()
            return GLib.SOURCE_REMOVE
        self.retry_sources[name] = GLib.timeout_add_seconds(seconds, retry)

    def cancel_retries(self):
        for source in self.retry_sources.values():
            GLib.source_remove(source)
        self.retry_sources.clear()

    def sync(self):
        active = bool(self.games)
        if active:
            if self.cookie is None and time.monotonic() >= self.next_retry:
                try:
                    self.connect_system()
                    result = self.call('HoldProfile', GLib.Variant(
                        '(sss)', ('performance', 'Steam game running', 'steam-power-profile-watch')
                    ), GLib.VariantType.new('(u)'))
                    self.cookie = result.unpack()[0]
                    print(f'Performance hold acquired (cookie={self.cookie}; games={len(self.games)})', flush=True)
                except (GLib.Error, OSError) as exc:
                    print(f'Failed to acquire hold: {exc}', file=sys.stderr, flush=True)
                    self.close_connection()
                    self.next_retry = time.monotonic() + 30
                    self.schedule_retry('profile', self.sync)
            return

        if self.cookie is not None:
            self.close_connection()
        if time.monotonic() < self.next_retry:
            return
        try:
            if self.locked is None:
                return  # Unknown lock state: do not guess a power profile.
            desired = 'power-saver' if self.locked else 'balanced'
            self.connect_system()
            current = self.get_profile()
            if current != desired:
                self.set_profile(desired)
        except (GLib.Error, OSError) as exc:
            print(f'Failed to synchronize desktop power profile: {exc}', file=sys.stderr, flush=True)
            self.next_retry = time.monotonic() + 30
            self.schedule_retry('profile', self.sync)

    def update_lock(self, locked):
        if locked != self.locked:
            self.locked = locked
            print(f'Desktop {"locked" if locked else "unlocked"}', flush=True)
            self.sync()

    def on_lock_changed(self, connection, sender, path, interface, signal_name, params):
        self.update_lock(params.unpack()[0])

    def on_screensaver_owner_changed(self, connection, sender, path, interface, signal_name, params):
        name, old_owner, new_owner = params.unpack()
        if not new_owner:
            self.locked = None
        else:
            self.refresh_lock()

    def refresh_lock(self):
        try:
            self.update_lock(self.screen_locked())
        except GLib.Error as exc:
            self.locked = None
            print(f'Failed to query KDE lock state: {exc}', file=sys.stderr, flush=True)
            self.schedule_retry('lock', self.refresh_lock)

    def cleanup(self):
        self.cancel_retries()
        for pid in list(self.pid_watches):
            self.forget_pid(pid)
        self.close_connection()
        self.close_stream()

    def close_connection(self):
        if self.conn is not None:
            try:
                if self.cookie is not None and not self.conn.is_closed():
                    self.call('ReleaseProfile', GLib.Variant('(u)', (self.cookie,)))
                    print('Performance hold released', flush=True)
            except GLib.Error as exc:
                print(f'Hold release failed: {exc}', file=sys.stderr, flush=True)
            finally:
                try:
                    if not self.conn.is_closed():
                        self.conn.close_sync(None)
                except GLib.Error:
                    pass
        self.cookie = None
        self.conn = None


def main():
    libc = ctypes.CDLL(None, use_errno=True)
    libc.inotify_init1.argtypes = [ctypes.c_int]
    libc.inotify_init1.restype = ctypes.c_int
    libc.inotify_add_watch.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
    libc.inotify_add_watch.restype = ctypes.c_int
    fd = libc.inotify_init1(os.O_CLOEXEC | os.O_NONBLOCK)
    if fd < 0:
        raise OSError(ctypes.get_errno(), 'inotify_init1 failed')
    mask = 0x00000002 | 0x00000004 | 0x00000008 | 0x00000080 | 0x00000100 | 0x00000200 | 0x00000400 | 0x00000800
    LOG.parent.mkdir(parents=True, exist_ok=True)
    if libc.inotify_add_watch(fd, os.fsencode(LOG.parent), mask) < 0:
        raise OSError(ctypes.get_errno(), 'inotify_add_watch failed')

    monitor = Monitor()
    loop = GLib.MainLoop()
    session = monitor.session

    # Subscribe before querying the initial state, avoiding a lost transition.
    lock_subscription = session.signal_subscribe(
        SCREENSAVER, SCREENSAVER, 'ActiveChanged', SCREEN_OBJECT, None,
        Gio.DBusSignalFlags.NONE, monitor.on_lock_changed,
    )
    owner_subscription = session.signal_subscribe(
        'org.freedesktop.DBus', 'org.freedesktop.DBus', 'NameOwnerChanged',
        '/org/freedesktop/DBus', SCREENSAVER,
        Gio.DBusSignalFlags.NONE, monitor.on_screensaver_owner_changed,
    )

    def check_games():
        monitor.load()
        monitor.detect_steam()
        if monitor.steam_pid is None:
            monitor.games.clear()
        monitor.reconcile_watches()
        if monitor.conn is not None and monitor.conn.is_closed():
            monitor.close_connection()
        monitor.sync()

    def on_inotify(channel, condition):
        if condition & (GLib.IO_HUP | GLib.IO_ERR | GLib.IO_NVAL):
            print('Steam inotify watch failed', file=sys.stderr, flush=True)
            loop.quit()
            return GLib.SOURCE_REMOVE
        try:
            while os.read(fd, 65536):
                pass
        except BlockingIOError:
            pass
        check_games()
        return GLib.SOURCE_CONTINUE

    def stop():
        loop.quit()
        return GLib.SOURCE_REMOVE

    def on_signal(signum, frame):
        GLib.idle_add(stop)

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)
    channel = GLib.IOChannel.unix_new(fd)
    watch_id = GLib.io_add_watch(
        channel, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR | GLib.IO_NVAL,
        on_inotify,
    )
    try:
        check_games()
        monitor.refresh_lock()
        monitor.sync()
        print('Watching Steam game process log and KDE lock signals', flush=True)
        loop.run()
    finally:
        GLib.source_remove(watch_id)
        session.signal_unsubscribe(lock_subscription)
        session.signal_unsubscribe(owner_subscription)
        monitor.cleanup()
        os.close(fd)


if __name__ == '__main__':
    main()
