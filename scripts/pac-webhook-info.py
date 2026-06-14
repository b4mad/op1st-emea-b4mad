#!/usr/bin/env python3
"""Print PAC webhook config (URL + secret) for op1st-pipelines.

Reads live from the cluster via `oc` — nothing hardcoded:
  - URL    : Route pipelines-as-code-controller in openshift-pipelines
  - secret : Secret codeberg-pac-token key webhook.secret in op1st-gitops

Usage: oc login first, then ./pac-webhook-info.py
"""
import base64
import json
import re
import subprocess
import sys

# TOON value-quoting per spec §7.2 (github.com/toon-format/spec)
_NUMERIC = re.compile(r"^-?\d+(?:\.\d+)?(?:e[+-]?\d+)?$", re.I)


def toon_value(s):
    needs_quote = (
        s == ""
        or s != s.strip()
        or s in ("true", "false", "null")
        or _NUMERIC.match(s)
        or any(c in s for c in ':"\\[]{}')
        or any(ord(c) < 0x20 for c in s)
        or s.startswith("-")
    )
    if not needs_quote:
        return s
    esc = (
        s.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f'"{esc}"'


def toon_dump(obj):
    return "\n".join(f"{k}: {toon_value(v)}" for k, v in obj.items())

ROUTE_NS = "openshift-pipelines"
ROUTE = "pipelines-as-code-controller"
SECRET_NS = "op1st-gitops"
SECRET = "codeberg-pac-token"
SECRET_KEY = "webhook.secret"


def oc_json(args):
    try:
        out = subprocess.run(
            ["oc", "get", *args, "-o", "json"],
            check=True, capture_output=True, text=True,
        ).stdout
    except FileNotFoundError:
        sys.exit("error: `oc` not found on PATH")
    except subprocess.CalledProcessError as e:
        sys.exit(f"error: oc get {' '.join(args)} failed:\n{e.stderr.strip()}")
    return json.loads(out)


def main():
    route = oc_json(["route", ROUTE, "-n", ROUTE_NS])
    host = route["spec"]["host"]
    url = f"https://{host}"

    sec = oc_json(["secret", SECRET, "-n", SECRET_NS])
    raw = sec.get("data", {}).get(SECRET_KEY)
    if raw is None:
        sys.exit(f"error: key {SECRET_KEY!r} not in secret {SECRET_NS}/{SECRET}")
    token = base64.b64decode(raw).decode()

    print(toon_dump({"url": url, "secret": token}))


if __name__ == "__main__":
    main()
