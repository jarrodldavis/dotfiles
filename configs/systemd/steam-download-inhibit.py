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
WAKE_LEAD = 60
WAKE_UNIT = "steam-update-wake"

MANIFEST_RE = re.compile(r"appmanifest_\d+\.acf$")


class Monitor:
    def __init__(self):
        self.inotifywait = self.find_command(
            "inotifywait",
            "/home/linuxbrew/.linuxbrew/bin/inotifywait",
            str(Path.home() / ".linuxbrew/bin/inotifywait"),
        )
        self.systemctl = self.find_command("systemctl", "/usr/bin/systemctl")
        self.systemd_inhibit = self.find_command("systemd-inhibit", "/usr/bin/systemd-inhibit")
        self.systemd_run = self.find_command("systemd-run", "/usr/bin/systemd-run")
        self.sleep = self.find_command("sleep", "/usr/bin/sleep")
        self.true = self.find_command("true", "/usr/bin/true")
        self.steam_root = self.find_steam_root()

        self.libraries = ()
        self.activity_dirs = ()
        self.parent_dirs = ()
        self.watch_signature = None

        self.watcher_tasks = []
        self.rebuild_event = asyncio.Event()

        self.inhibitor_lock = asyncio.Lock()
        self.inhibitor = None

        self.last_activity = 0.0
        self.last_activity_source = ""
        self.next_activity_log = 0.0
        self.next_reconcile = 0.0

        self.wake_timestamp = None
        self.scheduled_update_timestamp = None

    @staticmethod
    def find_command(name, *fallbacks):
        if path := shutil.which(name):
            return path

        for path in fallbacks:
            if os.access(path, os.X_OK):
                return path

        raise RuntimeError(f"Could not find {name}")

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

            for name in ("downloading", "temp", "shadercache"):
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

    def category_for(self, path):
        path = path.rstrip("/")
        depotcache = str(self.steam_root / "depotcache")

        if path == depotcache or path.startswith(depotcache + "/"):
            return "depotcache"

        for category in ("downloading", "temp", "shadercache"):
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
        await self.run_command(self.systemctl, "--user", "stop", f"{WAKE_UNIT}.timer", f"{WAKE_UNIT}.service")
        self.wake_timestamp = None
        self.scheduled_update_timestamp = None

    async def update_wake_timer(self, force=False):
        next_update = await asyncio.to_thread(self.find_next_scheduled_update)

        if next_update is None:
            if force or self.wake_timestamp is not None:
                await self.cancel_wake_timer()
                print("No future Steam updates are currently scheduled")
            return

        update_timestamp, appid, name = next_update
        wake_timestamp = update_timestamp - WAKE_LEAD

        if wake_timestamp <= time.time():
            wake_timestamp = update_timestamp

        if not force and update_timestamp == self.scheduled_update_timestamp:
            return

        await self.cancel_wake_timer()

        returncode, output = await self.run_command(
            self.systemd_run,
            "--user",
            f"--unit={WAKE_UNIT}",
            "--collect",
            f"--on-calendar=@{wake_timestamp}",
            "--timer-property=WakeSystem=true",
            "--timer-property=AccuracySec=1s",
            "--description=Wake for Steam scheduled update",
            self.true,
        )

        if returncode != 0:
            message = output or f"systemd-run exited with status {returncode}"
            print(f"Failed to schedule Steam wake: {message}", file=sys.stderr)
            return

        self.wake_timestamp = wake_timestamp
        self.scheduled_update_timestamp = update_timestamp
        print(f"Next Steam update: {self.format_timestamp(update_timestamp)} - {name} ({appid})")
        print(f"Scheduled system wake: {self.format_timestamp(wake_timestamp)}")

    async def record_activity(self, source):
        self.last_activity = time.monotonic()
        self.last_activity_source = source

        async with self.inhibitor_lock:
            if self.inhibitor is not None and self.inhibitor.returncode is None:
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

            self.next_activity_log = time.monotonic() + LOG_INTERVAL

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
            self.next_activity_log = 0.0

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

                    if "DELETE_SELF" in event_names or "MOVE_SELF" in event_names:
                        self.rebuild_event.set()
                else:
                    await self.handle_parent_event(path, event_names)

            self.rebuild_event.set()

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
            await self.update_wake_timer()
            return

        if base == "libraryfolders.vdf":
            if self.signature(self.discover_watch_paths()) != self.watch_signature:
                print("Steam library configuration changed")
                self.rebuild_event.set()

            return

        if base not in {"downloading", "temp", "shadercache"}:
            return

        print(f"Steam activity directory changed: {path}")

        if "CREATE" in event_names or "MOVED_TO" in event_names:
            await self.record_activity(f"{base}: {path} ({event_names})")

        self.rebuild_event.set()

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

        for root in self.activity_dirs:
            for dirpath, _, filenames in os.walk(root):
                for filename in filenames:
                    path = Path(dirpath) / filename

                    try:
                        if path.stat().st_mtime < cutoff:
                            continue
                    except OSError:
                        continue

                    category = self.category_for(str(path)) or "activity"
                    return f"{category}: {path}"

        return None

    async def check_recent_activity(self):
        if recent := await asyncio.to_thread(self.find_recent_activity):
            await self.record_activity(recent)

    async def rebuild_watchers(self):
        self.rebuild_event.clear()
        await self.stop_watchers()
        await asyncio.sleep(0.25)

        print("Rebuilding Steam watches")

        await self.start_watchers()
        await self.check_recent_activity()
        await self.update_wake_timer()

    async def reconcile(self):
        paths = self.discover_watch_paths()

        if self.signature(paths) != self.watch_signature:
            print("Steam watch paths changed; rebuilding watches")
            await self.stop_watchers()
            await self.start_watchers()
            await self.check_recent_activity()
            await self.update_wake_timer()
        else:
            self.next_reconcile = time.monotonic() + RECONCILE_INTERVAL

    async def handle_deadlines(self):
        now = time.monotonic()

        if now >= self.next_reconcile:
            await self.reconcile()

            if self.scheduled_update_timestamp is not None and time.time() >= self.scheduled_update_timestamp:
                await self.update_wake_timer()

            now = time.monotonic()

        if self.inhibitor is None or self.inhibitor.returncode is not None:
            return

        if now >= self.last_activity + ACTIVITY_TIMEOUT:
            await self.stop_inhibitor()
        elif now >= self.next_activity_log:
            print(f"Steam activity: {self.last_activity_source}")
            self.next_activity_log = now + LOG_INTERVAL

    def next_timeout(self):
        now = time.monotonic()
        deadlines = [self.next_reconcile]

        if self.inhibitor is not None and self.inhibitor.returncode is None:
            deadlines += [self.last_activity + ACTIVITY_TIMEOUT, self.next_activity_log]

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
        asyncio.run(main())
    except RuntimeError as exc:
        raise SystemExit(str(exc))
