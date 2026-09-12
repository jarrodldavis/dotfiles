#!/usr/bin/env python3

import asyncio
import os
import re
import shutil
import signal
import sys
import time
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

ACTIVITY_TIMEOUT = 5 * 60
LOG_INTERVAL = 5 * 60
RECONCILE_INTERVAL = 60
MAX_WAKE_INTERVAL = 6 * 60 * 60
WAKE_LEAD = 60
WAKE_SCREEN_OFF_DELAY = 2
WAKE_SERVICE = "steam-update-wake.service"
WAKE_TIMER = "steam-update-wake.timer"

MANIFEST_RE = re.compile(r"appmanifest_\d+\.acf$")


def find_command(name, *fallbacks):
    if path := shutil.which(name):
        return path

    for path in fallbacks:
        if os.access(path, os.X_OK):
            return path

    raise RuntimeError(f"Could not find {name}")


async def wake_action():
    await asyncio.sleep(WAKE_SCREEN_OFF_DELAY)

    dbus_send = find_command("dbus-send", "/usr/bin/dbus-send")
    proc = await asyncio.create_subprocess_exec(
        dbus_send,
        "--session",
        "--print-reply",
        "--dest=org.freedesktop.ScreenSaver",
        "/ScreenSaver",
        "org.freedesktop.ScreenSaver.GetActive",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
    )
    output, _ = await proc.communicate()

    if proc.returncode != 0:
        print("Could not determine lock state; leaving display on", file=sys.stderr)
        return

    if b"boolean true" not in output:
        print("Session is unlocked; leaving display on")
        return

    print("Session is locked; turning off display")

    proc = await asyncio.create_subprocess_exec(
        dbus_send,
        "--session",
        "--print-reply",
        "--dest=org.kde.kglobalaccel",
        "/component/org_kde_powerdevil",
        "org.kde.kglobalaccel.Component.invokeShortcut",
        "string:Turn Off Screen",
    )
    await proc.wait()


class Monitor:
    def __init__(self):
        self.inotifywait = find_command(
            "inotifywait",
            "/home/linuxbrew/.linuxbrew/bin/inotifywait",
            str(Path.home() / ".linuxbrew/bin/inotifywait"),
        )
        self.systemctl = find_command("systemctl", "/usr/bin/systemctl")
        self.systemd_inhibit = find_command("systemd-inhibit", "/usr/bin/systemd-inhibit")
        self.systemd_run = find_command("systemd-run", "/usr/bin/systemd-run")
        self.sleep = find_command("sleep", "/usr/bin/sleep")
        self.steam_root = self.find_steam_root()

        self.libraries = ()
        self.activity_dirs = ()
        self.parent_dirs = ()
        self.watch_signature = None

        self.watcher_tasks = []
        self.rebuild_event = asyncio.Event()
        self.rebuild_reason = None

        self.inhibitor_lock = asyncio.Lock()
        self.inhibitor = None
        self.last_activity = 0.0
        self.last_activity_log = 0.0
        self.next_reconcile = 0.0

        self.discovery_deadline = int(time.time()) + MAX_WAKE_INTERVAL
        self.wake_timestamp = None
        self.scheduled_update_timestamp = None

    @staticmethod
    def find_steam_root():
        for path in (
            Path.home() / ".steam/root",
            Path.home() / ".local/share/Steam",
            Path.home() / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
        ):
            if path.is_dir():
                return path.resolve()

        raise RuntimeError("Could not find Steam installation")

    def get_libraries(self):
        libraries = [self.steam_root]
        seen = {str(self.steam_root)}
        path_re = re.compile(r'^\s*"path"\s+"(.*)"\s*$')

        for vdf in (self.steam_root / "config/libraryfolders.vdf", self.steam_root / "steamapps/libraryfolders.vdf"):
            try:
                lines = vdf.read_text(errors="replace").splitlines()
            except OSError:
                continue

            for line in lines:
                match = path_re.match(line)
                if not match:
                    continue

                value = match.group(1).replace(r"\\", "\\").replace(r"\"", '"')
                path = Path(value).expanduser()

                if str(path) not in seen:
                    libraries.append(path)
                    seen.add(str(path))

        return tuple(libraries)

    def discover_watch_paths(self):
        libraries = self.get_libraries()
        activity_dirs = []
        parent_dirs = []

        depotcache = self.steam_root / "depotcache"
        if depotcache.is_dir():
            activity_dirs.append(depotcache)

        for library in libraries:
            steamapps = library / "steamapps"

            if steamapps.is_dir():
                parent_dirs.append(steamapps)

            for name in ("downloading", "temp"):
                path = steamapps / name
                if path.is_dir():
                    activity_dirs.append(path)

        config = self.steam_root / "config"
        if config.is_dir():
            parent_dirs.append(config)

        return libraries, tuple(dict.fromkeys(activity_dirs)), tuple(dict.fromkeys(parent_dirs))

    @staticmethod
    def signature(paths):
        return tuple(tuple(map(str, group)) for group in paths)

    def request_rebuild(self, reason):
        print(f"Steam watch rebuild requested: {reason}")

        if not self.rebuild_event.is_set():
            self.rebuild_reason = reason
            self.rebuild_event.set()

    def is_activity_root(self, path):
        path = os.path.normpath(path)
        return any(path == os.path.normpath(str(root)) for root in self.activity_dirs)

    def category_for(self, path):
        path = path.rstrip("/")
        depotcache = str(self.steam_root / "depotcache")

        if path == depotcache or path.startswith(depotcache + "/"):
            return "depotcache"

        for category in ("downloading", "temp"):
            needle = f"/steamapps/{category}"
            if path.endswith(needle) or needle + "/" in path:
                return category

        return None

    def find_next_scheduled_update(self):
        now = time.time()
        next_update = None
        field_re = re.compile(r'^\s*"([^"]+)"\s+"(.*)"\s*$')

        for library in self.libraries:
            steamapps = library / "steamapps"

            for manifest in steamapps.glob("appmanifest_*.acf"):
                fields = {}

                try:
                    for line in manifest.read_text(errors="replace").splitlines():
                        if match := field_re.match(line):
                            fields.setdefault(match.group(1), match.group(2))
                except OSError:
                    continue

                try:
                    timestamp = int(fields.get("ScheduledAutoUpdate", "0"))
                except ValueError:
                    continue

                if timestamp <= now:
                    continue

                update = (
                    timestamp,
                    fields.get("appid", manifest.stem.removeprefix("appmanifest_")),
                    fields.get("name", manifest.stem),
                )

                if next_update is None or update[0] < next_update[0]:
                    next_update = update

        return next_update

    @staticmethod
    def format_timestamp(timestamp):
        return time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(timestamp))

    async def run_command(self, *args):
        proc = await asyncio.create_subprocess_exec(
            *args, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT
        )
        output, _ = await proc.communicate()
        return proc.returncode, output.decode(errors="replace").strip()

    async def cancel_wake_timer(self):
        await self.run_command(self.systemctl, "--user", "stop", WAKE_TIMER)
        self.wake_timestamp = None
        self.scheduled_update_timestamp = None

    async def wait_for_wake_service(self):
        while True:
            _, state = await self.run_command(
                self.systemctl,
                "--user",
                "show",
                "--property=ActiveState",
                "--value",
                WAKE_SERVICE,
            )

            if state not in {"active", "activating", "deactivating", "reloading"}:
                return

            await asyncio.sleep(0.1)

    def refresh_discovery_deadline(self):
        self.discovery_deadline = int(time.time()) + MAX_WAKE_INTERVAL

    async def update_wake_timer(self, force=False):
        now = int(time.time())
        next_update = await asyncio.to_thread(self.find_next_scheduled_update)
        update_timestamp = next_update[0] if next_update is not None else None
        wake_timestamp = self.discovery_deadline
        wake_for_update = False

        if next_update is not None:
            scheduled_wake = update_timestamp - WAKE_LEAD

            if scheduled_wake > now and scheduled_wake < wake_timestamp:
                wake_timestamp = scheduled_wake
                wake_for_update = True

        if (
            not force
            and wake_timestamp == self.wake_timestamp
            and update_timestamp == self.scheduled_update_timestamp
        ):
            return

        await self.cancel_wake_timer()
        await self.wait_for_wake_service()

        returncode, output = await self.run_command(
            self.systemd_run,
            "--user",
            f"--unit={WAKE_SERVICE}",
            f"--on-calendar=@{wake_timestamp}",
            "--timer-property=WakeSystem=true",
            "--timer-property=AccuracySec=1s",
            "--timer-property=RemainAfterElapse=false",
            "--description=Wake for Steam update discovery",
        )

        if returncode != 0:
            message = output or f"systemd-run exited with status {returncode}"
            print(f"Failed to schedule Steam wake: {message}", file=sys.stderr)
            return

        self.wake_timestamp = wake_timestamp
        self.scheduled_update_timestamp = update_timestamp

        if next_update is None:
            print("No future Steam updates are currently scheduled")
        else:
            _, appid, name = next_update
            print(f"Next Steam update: {self.format_timestamp(update_timestamp)} - {name} ({appid})")

        reason = "scheduled update" if wake_for_update else "update discovery"
        print(f"Scheduled system wake: {self.format_timestamp(wake_timestamp)} ({reason})")

    async def record_activity(self, source):
        now = time.monotonic()
        self.last_activity = now

        async with self.inhibitor_lock:
            if self.inhibitor is not None and self.inhibitor.returncode is None:
                if now - self.last_activity_log >= LOG_INTERVAL:
                    print(f"Steam activity: {source}")
                    self.last_activity_log = now
                return

            print("Steam activity detected; inhibiting sleep")
            print(f"Steam activity: {source}")

            self.inhibitor = await asyncio.create_subprocess_exec(
                self.systemd_inhibit,
                "--what=sleep",
                "--mode=block",
                "--who=Steam",
                "--why=Steam download/update activity",
                self.sleep,
                "infinity",
                start_new_session=True,
            )
            self.last_activity_log = now

    async def stop_inhibitor(self):
        async with self.inhibitor_lock:
            if self.inhibitor is None:
                return

            if self.inhibitor.returncode is None:
                print("Steam activity ended; releasing sleep inhibitor")

                try:
                    os.killpg(self.inhibitor.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass

                try:
                    await asyncio.wait_for(self.inhibitor.wait(), 2)
                except asyncio.TimeoutError:
                    try:
                        os.killpg(self.inhibitor.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass

                    await self.inhibitor.wait()

            self.inhibitor = None
            self.last_activity_log = 0.0

    async def watcher(self, kind, paths, recursive):
        if not paths:
            return

        args = [self.inotifywait, "-q", "-m"]
        if recursive:
            args.append("-r")

        events = ("create", "close_write", "moved_to", "moved_from", "delete")
        if kind == "activity":
            events += ("modify", "delete_self", "move_self")

        for event in events:
            args += ["-e", event]

        args += ["--format", "%w%f|%e", *map(str, paths)]
        proc = await asyncio.create_subprocess_exec(*args, stdout=asyncio.subprocess.PIPE)

        try:
            assert proc.stdout is not None

            while line := await proc.stdout.readline():
                try:
                    path, event_names = line.decode(errors="replace").rstrip("\n").rsplit("|", 1)
                except ValueError:
                    continue

                if kind == "activity":
                    category = self.category_for(path)

                    if category:
                        await self.record_activity(f"{category}: {path} ({event_names})")

                    root_invalidated = (
                        ("DELETE_SELF" in event_names or "MOVE_SELF" in event_names) and self.is_activity_root(path)
                    )
                    if root_invalidated:
                        self.request_rebuild(f"activity root invalidated: {path} ({event_names})")
                else:
                    await self.handle_parent_event(path, event_names)

            returncode = await proc.wait()
            self.request_rebuild(f"{kind} inotifywait exited with status {returncode}")

        finally:
            if proc.returncode is None:
                proc.terminate()

                try:
                    await asyncio.wait_for(proc.wait(), 2)
                except asyncio.TimeoutError:
                    proc.kill()
                    await proc.wait()

    async def handle_parent_event(self, path, event_names):
        base = Path(path).name

        if MANIFEST_RE.fullmatch(base):
            self.refresh_discovery_deadline()
            await self.update_wake_timer()
            return

        if base == "libraryfolders.vdf":
            if self.signature(self.discover_watch_paths()) != self.watch_signature:
                self.request_rebuild(f"Steam library configuration changed: {path} ({event_names})")
            return

        if base not in {"downloading", "temp"}:
            return

        if "CREATE" in event_names or "MOVED_TO" in event_names:
            await self.record_activity(f"{base}: {path} ({event_names})")

        self.request_rebuild(f"Steam activity directory changed: {path} ({event_names})")

    async def stop_watchers(self):
        tasks = self.watcher_tasks
        self.watcher_tasks = []

        for task in tasks:
            task.cancel()

        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)

    async def start_watchers(self):
        paths = self.discover_watch_paths()
        self.libraries, self.activity_dirs, self.parent_dirs = paths
        self.watch_signature = self.signature(paths)

        self.watcher_tasks = [
            asyncio.create_task(self.watcher("activity", self.activity_dirs, True)),
            asyncio.create_task(self.watcher("parent", self.parent_dirs, False)),
        ]

        print("Watching Steam libraries:")
        for library in self.libraries:
            print(f"  {library}")

        self.next_reconcile = time.monotonic() + RECONCILE_INTERVAL

    def find_recent_activity(self):
        cutoff = time.time() - ACTIVITY_TIMEOUT
        latest = None

        for root in self.activity_dirs:
            for dirpath, _, filenames in os.walk(root):
                for filename in filenames:
                    path = Path(dirpath) / filename

                    try:
                        modified = path.stat().st_mtime
                    except OSError:
                        continue

                    if modified < cutoff:
                        continue

                    if latest is None or modified > latest[0]:
                        category = self.category_for(str(path)) or "activity"
                        latest = modified, f"{category}: {path}"

        return latest[1] if latest is not None else None

    async def check_recent_activity(self):
        if recent := await asyncio.to_thread(self.find_recent_activity):
            await self.record_activity(recent)

    async def rebuild_watchers(self):
        reason = self.rebuild_reason or "unspecified"
        self.rebuild_reason = None
        self.rebuild_event.clear()

        print(f"Rebuilding Steam watches: {reason}")

        await self.stop_watchers()
        await asyncio.sleep(0.25)
        await self.start_watchers()
        await self.check_recent_activity()
        await self.update_wake_timer()

    async def reconcile(self):
        paths = self.discover_watch_paths()
        self.next_reconcile = time.monotonic() + RECONCILE_INTERVAL

        if self.signature(paths) != self.watch_signature:
            self.request_rebuild("periodic reconciliation detected changed Steam watch paths")

    async def handle_deadlines(self):
        now = time.monotonic()
        wall_now = int(time.time())

        if now >= self.next_reconcile:
            await self.reconcile()

            if self.wake_timestamp is not None and wall_now >= self.wake_timestamp:
                self.refresh_discovery_deadline()
                await self.update_wake_timer(force=True)
            elif self.scheduled_update_timestamp is not None and wall_now >= self.scheduled_update_timestamp:
                await self.update_wake_timer()

            now = time.monotonic()

        if self.inhibitor is not None and self.inhibitor.returncode is None:
            if now >= self.last_activity + ACTIVITY_TIMEOUT:
                await self.stop_inhibitor()

    def next_timeout(self):
        now = time.monotonic()
        deadlines = [self.next_reconcile]

        if self.inhibitor is not None and self.inhibitor.returncode is None:
            deadlines.append(self.last_activity + ACTIVITY_TIMEOUT)

        return max(0, min(deadlines) - now)

    async def run(self):
        print(f"Steam root: {self.steam_root}")
        print(f"inotifywait: {self.inotifywait}")

        await self.start_watchers()
        await self.check_recent_activity()
        await self.update_wake_timer(force=True)

        while True:
            await self.handle_deadlines()

            try:
                await asyncio.wait_for(self.rebuild_event.wait(), self.next_timeout())
            except asyncio.TimeoutError:
                continue

            await self.rebuild_watchers()

    async def cleanup(self):
        await self.stop_watchers()
        await self.stop_inhibitor()
        await self.cancel_wake_timer()


async def main():
    monitor = Monitor()
    task = asyncio.current_task()
    loop = asyncio.get_running_loop()

    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, task.cancel)

    try:
        await monitor.run()
    except asyncio.CancelledError:
        pass
    finally:
        await monitor.cleanup()


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["--wake-action"]:
            asyncio.run(wake_action())
        elif sys.argv[1:]:
            raise SystemExit(f"Unknown arguments: {' '.join(sys.argv[1:])}")
        else:
            asyncio.run(main())
    except RuntimeError as exc:
        raise SystemExit(str(exc))
