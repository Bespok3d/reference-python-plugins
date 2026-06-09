#!/usr/bin/env python3
"""A small own-service sidecar serving a human-readable printer status summary as JSON.

Reference plugin for ADR-0036. It runs in its own per-plugin virtual environment, declared by the
manifest's `install.python` block, so its single dependency (`humanize`) never touches the system,
Klipper, or Moonraker interpreters. It polls Moonraker over its local HTTP API and serves the
summary, which the plugin's nginx web-location proxies to the browser at /status-feed/.
"""
import argparse
import json
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import humanize

MOONRAKER_QUERY = (
    "http://127.0.0.1:7125/printer/objects/query"
    "?print_stats&display_status&virtual_sdcard"
)
QUERY_TIMEOUT_S = 4
DEFAULT_BIND = "127.0.0.1"
DEFAULT_PORT = 8097


def query_moonraker() -> dict:
    with urllib.request.urlopen(MOONRAKER_QUERY, timeout=QUERY_TIMEOUT_S) as response:
        payload = json.loads(response.read().decode(errors="replace"))
    return payload.get("result", {}).get("status", {})


def summarize(status: dict) -> dict:
    """Reduce Moonraker's raw objects to the four fields a human wants to read."""
    print_stats = status.get("print_stats", {})
    display = status.get("display_status", {})
    sdcard = status.get("virtual_sdcard", {})
    progress = display.get("progress", sdcard.get("progress", 0.0))
    return {
        "state": print_stats.get("state", "unknown"),
        "filename": print_stats.get("filename", ""),
        "elapsed": humanize.naturaldelta(print_stats.get("print_duration", 0.0)),
        "progress": f"{round(progress * 100)}%",
    }


def status_payload() -> bytes:
    try:
        summary = summarize(query_moonraker())
    except Exception as unreachable:  # noqa: BLE001 - Moonraker down is a normal, reportable state
        summary = {"state": "unreachable", "error": str(unreachable)}
    return json.dumps(summary).encode()


class StatusHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802 - name fixed by BaseHTTPRequestHandler
        body = status_payload()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args: object) -> None:
        return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bespok3d status feed sidecar")
    parser.add_argument("--bind", default=DEFAULT_BIND)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    ThreadingHTTPServer((args.bind, args.port), StatusHandler).serve_forever()


if __name__ == "__main__":
    main()
