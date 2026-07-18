# reference-python-plugins

A co-repo of small Bespok3d plugins that exist as the **reference implementation** for shipping Python
dependencies in a plugin without ever running pip on the printer (ADR-0036). The invariant: never pip
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

## Releasing

Bump a plugin's `manifest.json` `version` and push to `main`. CI runs the `Bespok3d/b3-builder`
Action over the whole repo, which packs each `.b3`, cuts a release per plugin, assembles this repo's
`index.json` sub-list as `Reference Python Plugins`, and registers it in `Bespok3d/main-index`
(`lists/<repo>.json`). Secret: `MAIN_INDEX_TOKEN` (contents:write on main-index). Signing deferred.

> Not yet verified on a physical U1.

## Maintainership

These plugins are published and maintained by the Bespok3d org, and several of them repackage or
build on upstream source material. If you own the source material a plugin is based on and would
rather manage it yourself, you are welcome to contact the org to claim it back. The one condition is
that it stays actively maintained: a claimed plugin left to rot will be reclaimed so users are never
stranded on an abandoned package.
