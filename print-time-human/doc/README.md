# Print Time (Human)

Adds one Klipper G-code command:

```
PRINT_TIME_HUMAN   ->   // Elapsed: 2 hours
```

It is the reference for a **Klipper extra that needs a third-party Python library**. The dependency
here is `humanize`, which the printer does not ship. The extra itself is a plain, unmodified Klipper
extra: it just `import humanize`. Any existing Klipper extra drops in the same way.

## Why it is built this way

Klipper imports an extra into the system Python interpreter, which is also Moonraker's and must
never be `pip`-ed into (that is what broke Moonraker once). So the dependency is made importable
without touching that interpreter's package manager:

1. The plugin declares its dependency in a plain `klipper_requirements.txt` (a standard requirements
   file, not a manifest field). The name marks that the dep targets Klipper/Moonraker's interpreter,
   not the plugin's own venv.
2. At publish time, CI bakes that dependency, unpacked, into `files/site-packages/`. The `.b3` is
   self-contained; nothing is fetched at install.
3. At install, the daemon symlinks each baked package into the system `site-packages`, so Klipper
   can `import` it. It refuses to shadow a package the firmware already ships, and refuses a version
   clash with another plugin. Deactivate and uninstall remove the links.

The author writes no bootstrap code: the extra imports normally. Pure-Python dependencies only: an
extra shares Klipper's process, so a compiled dependency would have to match Klipper's interpreter
and could clash with what Klipper already ships. A plugin that needs a compiled dependency should
run its own service (declaring `requirements.txt`, which goes into the plugin's own venv) and talk
to Klipper over its API.

## Build

```sh
npm install github:Bespok3d/b3-builder
npx b3-builder build --source ./print-time-human --atom-repo Bespok3d/reference-python-plugins --bake
# --bake installs klipper_requirements.txt into files/site-packages, then packs
# -> dist/print-time-human-<version>.b3
```
