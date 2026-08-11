# reference-python-plugins

[![licence](https://img.shields.io/badge/licence-AGPL--3.0-blue)](LICENSE)
[![release](https://img.shields.io/github/v/release/Bespok3d/reference-python-plugins)](https://github.com/Bespok3d/reference-python-plugins/releases)
![printer](https://img.shields.io/badge/printer-Snapmaker%20U1-informational)
![stock firmware](https://img.shields.io/badge/stock%20firmware-no%20flashing-brightgreen)

A co-repo of small Bespok3d plugins that exist as the **reference implementation** for shipping Python
dependencies in a plugin without ever running pip on the printer. The invariant: never pip
into the system, Klipper, or Moonraker interpreters. Each plugin declares its deps as a plain
requirements file; CI bakes them into the `.b3`, and the daemon installs them offline.

The two modes, one plugin each:

- **`status-feed`** (own-service venv): ships a `requirements.txt`. CI fetches the dependency closure as
  wheels into `files/wheels/`; the daemon provisions a per-plugin venv at `$BESPOK3D/venv-plugins/<id>/`
  and installs them offline (`pip install --no-index --find-links files/wheels`). The plugin's own
  Python service runs with `$PLUGIN_VENV/bin/python3`.
- **`print-time-human`** (Klipper extra): ships a `klipper_requirements.txt`. CI bakes the unpacked
  packages into `files/site-packages/`; the daemon symlinks each top-level package into the system
  site-packages so the Klipper extra can `import` it, guarded against shadowing or version collisions.

Both examples use a pure-Python dependency (`humanize`), so any interpreter works and no compiled build
is needed. A plugin with a compiled dependency would prebuild that wheel on an arm64 runner first (see
`u1-hw-camera`).

## Build locally

Needs Node.js 20+. Builds run through the shared `Bespok3d/b3-builder` tool:

```sh
npm install github:Bespok3d/b3-builder
npx b3-builder build --source ./status-feed --atom-repo Bespok3d/reference-python-plugins
# -> dist/status-feed-<ver>.b3 + dist/status-feed.atom.json
```

Drop `--source` to build every plugin in the repo at once.

The Action runs with `bake: 'true'`: a plugin that ships a `requirements.txt` or
`klipper_requirements.txt` at its root gets its Python deps downloaded for the printer platform
(aarch64, CPython 3.11) at build time. Pass `--bake` to do the same locally.

Writing a plugin of your own? Start at the plugin documentation:
[Bespok3d/b3-builder/doc](https://github.com/Bespok3d/b3-builder/tree/main/doc).

## Releasing

Bump a plugin's `manifest.json` `version` and push the tag `plugin-<name>-v<version>` naming that
plugin and that exact number. A push to `main` publishes nothing, and the run is refused if the tag
and the manifest disagree. CI runs the `Bespok3d/b3-builder` Action over the whole repo, which packs
each `.b3`, cuts a release per plugin, assembles this repo's `index.json` sub-list as `Reference
Python Plugins`, and registers it in `Bespok3d/main-index` (`lists/<repo>.json`). Secrets:
`MAIN_INDEX_TOKEN` (contents:write on main-index) and `REGISTRY_SIGNING_KEY` (the org registry key
the `b3-builder` Action signs each `.b3` and atom with).

> Installed and running on a Snapmaker U1.

## Maintainership

These plugins are published and maintained by the Bespok3d org, and several of them repackage or
build on upstream source material. If you own the source material a plugin is based on and would
rather manage it yourself, you are welcome to contact the org to claim it back. The one condition is
that it stays actively maintained: a claimed plugin left to rot will be reclaimed so users are never
stranded on an abandoned package.

## Licence

Copyright (C) 2026 unlucio and the Bespok3d contributors

This program is free software: you can redistribute it and/or modify it under the terms of the GNU
Affero General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If
not, see <https://www.gnu.org/licenses/>. The full text is in [LICENSE](LICENSE).

Bespok3d is a project of the Bespok3d Organisation, which is not a legal entity. Copyright is held by
the individual authors named above.

## Support this project

`status-feed` is Bespok3d's own work. `print-time-human` packages software written by other people,
and a donation here is not a donation to them.

If our part saved you an afternoon, you can [buy me a coffee](https://buymeacoffee.com/unlucio).
