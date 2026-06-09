# Status Feed

A small sidecar that serves a human-readable print-status summary as JSON at
`http://<printer-ip>/status-feed/`. Point a dashboard tile, a phone shortcut, or a script at it.

```json
{ "state": "printing", "filename": "bracket.gcode", "elapsed": "an hour", "progress": "42%" }
```

## Why it exists

Status Feed is the reference plugin for a **plugin that runs its own Python service** and needs a
package the printer does not ship: `humanize`. The dependency is declared as data, never a script:
the plugin ships a plain `requirements.txt` (the universal Python convention, not a manifest field):

```
humanize>=4.9.0
```

The `install.service` command just points at the plugin's own interpreter:

```json
"install": {
  "service": [{ "command": "$PLUGIN_VENV/bin/python3", "args": ["..."], "autostart": true }]
}
```

At publish time, CI bakes `humanize` into `files/wheels/` (`scripts/fetch-wheels.sh`). At install,
the daemon sees the `requirements.txt`, builds a private virtual environment at
`$BESPOK3D/venv-plugins/status-feed/`, installs into it **offline** from the baked wheels
(`pip install --no-index --find-links files/wheels -r requirements.txt`), and exposes that venv as
`$PLUGIN_VENV`. Nothing is fetched at install, and the system, Klipper, and Moonraker interpreters
are never touched. Uninstall and deactivate delete the venv.

(A plugin whose dependency must instead be importable by Klipper or Moonraker's own interpreter
ships a `klipper_requirements.txt` instead; the two files are mutually exclusive. See
`klipper-print-time-human` for that case.)

## Access

Once installed: `http://<printer-ip>/status-feed/`
