#!/usr/bin/python3 -u
"""Hold TuneD performance while Steam has tracked games running (Linux)."""
import ctypes
import errno
import os
import re
import select
import signal
import sys
import time
from pathlib import Path

from gi.repository import Gio, GLib

LOG = Path.home() / '.local/share/Steam/logs/gameprocess_log.txt'
SERVICE = 'net.hadess.PowerProfiles'
OBJECT = '/net/hadess/PowerProfiles'
TIMEOUT_MS = 5000

# Steam logs 64-bit non-Steam shortcut IDs for launches, but signed 32-bit
# shortcut IDs for "Remove ... from running list" events.
def app_key(value):
    number = int(value)
    return ((number >> 32) if number > 0xFFFFFFFF else number) & 0xFFFFFFFF

ADD = re.compile(r'AppID (\d+) adding PID (\d+) as a tracked process')
REMOVE = re.compile(r'Remove (-?\d+) from running list')
CLIENT = re.compile(r'Client version: ')


def running(pid):
    try:
        # Zombie processes are no longer running.
        return Path(f'/proc/{pid}/stat').read_text().rsplit(') ', 1)[1][0] != 'Z'
    except (FileNotFoundError, ProcessLookupError, PermissionError, IndexError):
        return False


def steam_running():
    for directory in Path('/proc').iterdir():
        if directory.name.isdigit():
            try:
                if (directory / 'comm').read_text().strip() == 'steam' and running(directory.name):
                    return True
            except (OSError, UnicodeError):
                pass
    return False


class Monitor:
    def __init__(self):
        self.games = {}
        self.conn = None
        self.cookie = None
        self.next_retry = 0
        self.stream = None
        self.identity = None

    def process(self, line):
        if CLIENT.search(line):
            self.games.clear()
            return
        m = ADD.search(line)
        if m:
            self.games.setdefault(app_key(m[1]), set()).add(int(m[2]))
            return
        m = REMOVE.search(line)
        if m:
            self.games.pop(app_key(m[1]), None)

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
            # The log can contain older sessions and dead processes.
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

    def sync_hold(self):
        active = bool(self.games)
        if active and self.cookie is None and time.monotonic() >= self.next_retry:
            try:
                address = Gio.dbus_address_get_for_bus_sync(Gio.BusType.SYSTEM, None)
                self.conn = Gio.DBusConnection.new_for_address_sync(
                    address,
                    Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT |
                    Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
                    None, None,
                )
                result = self.call('HoldProfile', GLib.Variant(
                    '(sss)', ('performance', 'Steam game running', 'steam-power-profile-watch')
                ), GLib.VariantType.new('(u)'))
                self.cookie = result.unpack()[0]
                print(f'Performance hold acquired (cookie={self.cookie}; games={len(self.games)})', flush=True)
            except (GLib.Error, OSError) as exc:
                print(f'Failed to acquire hold: {exc}', file=sys.stderr, flush=True)
                self.close_connection()
                self.next_retry = time.monotonic() + 30
        elif not active and self.cookie is not None:
            self.close_connection()

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
                    self.conn.close_sync(None)
                except GLib.Error:
                    pass
        self.cookie = None
        self.conn = None


def main():
    # Inotify watches the parent, not the file, so replacement and recreation
    # of the log also trigger a read.
    libc = ctypes.CDLL(None, use_errno=True)
    libc.inotify_init1.argtypes = [ctypes.c_int]
    libc.inotify_init1.restype = ctypes.c_int
    libc.inotify_add_watch.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
    libc.inotify_add_watch.restype = ctypes.c_int
    fd = libc.inotify_init1(os.O_CLOEXEC | os.O_NONBLOCK)
    if fd < 0:
        raise OSError(ctypes.get_errno(), 'inotify_init1 failed')
    # IN_MODIFY | IN_ATTRIB | IN_CLOSE_WRITE | IN_MOVED_TO | IN_CREATE |
    # IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF
    mask = 0x00000002 | 0x00000004 | 0x00000008 | 0x00000080 | 0x00000100 | 0x00000200 | 0x00000400 | 0x00000800
    LOG.parent.mkdir(parents=True, exist_ok=True)
    if libc.inotify_add_watch(fd, os.fsencode(LOG.parent), mask) < 0:
        raise OSError(ctypes.get_errno(), 'inotify_add_watch failed')

    monitor = Monitor()
    def stop(signum, frame):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        monitor.load()
        if not steam_running():
            monitor.games.clear()
        monitor.sync_hold()
        print('Watching Steam game process log', flush=True)
        while True:
            ready, _, _ = select.select([fd], [], [], 5)
            if ready:
                try:
                    while os.read(fd, 65536):
                        pass
                except BlockingIOError:
                    pass
            monitor.load()
            # Prevent stale holds after an unclean Steam shutdown.
            if monitor.games and not steam_running():
                monitor.games.clear()
            # If the owner connection is lost, acquire a fresh hold.
            if monitor.conn is not None and monitor.conn.is_closed():
                monitor.close_connection()
            monitor.sync_hold()
    finally:
        monitor.close_connection()
        monitor.close_stream()
        os.close(fd)


if __name__ == '__main__':
    main()
