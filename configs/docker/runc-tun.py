#!/usr/bin/env python3
import json
import os
import shutil
import sys
import tempfile

args = sys.argv[1:]

if "create" in args or "run" in args:
    bundle = os.getcwd()

    for i, arg in enumerate(args):
        if arg in ("--bundle", "-b") and i + 1 < len(args):
            bundle = args[i + 1]
            break
        if arg.startswith("--bundle="):
            bundle = arg.split("=", 1)[1]
            break

    path = os.path.join(bundle, "config.json")

    with open(path) as f:
        spec = json.load(f)

    linux = spec.setdefault("linux", {})
    devices = linux.setdefault("devices", [])

    if not any(d.get("path") == "/dev/net/tun" for d in devices):
        devices.append({
            "path": "/dev/net/tun",
            "type": "c",
            "major": 10,
            "minor": 200,
            "fileMode": 0o666,
            "uid": 0,
            "gid": 0
        })

    resources = linux.setdefault("resources", {})
    rules = resources.setdefault("devices", [])

    if not any(
        r.get("allow") is True
        and r.get("type") == "c"
        and r.get("major") == 10
        and r.get("minor") == 200
        and set("rw").issubset(set(r.get("access", "")))
        for r in rules
    ):
        rules.append({
            "allow": True,
            "type": "c",
            "major": 10,
            "minor": 200,
            "access": "rwm"
        })

    fd, tmp = tempfile.mkstemp(dir=bundle)
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(spec, f)
        shutil.copymode(path, tmp)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)

os.execv("/usr/bin/runc", ["runc", *args])
