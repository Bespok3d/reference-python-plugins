#!/bin/sh
# Bake each plugin's Python dependencies into its files/ so the printer never runs pip (ADR-0036).
# Two modes, chosen by which requirements file a plugin ships:
#   requirements.txt          -> wheels for the plugin's OWN service venv. The daemon installs them
#                                offline (pip install --no-index --find-links files/wheels) into a
#                                per-plugin venv. We fetch the full closure as wheels into files/wheels.
#   klipper_requirements.txt  -> unpacked packages for a Klipper/Moonraker EXTRA that must import the
#                                lib in THAT (system) interpreter. pip install --target gives a flat
#                                importable dir; the daemon symlinks each top-level package into the
#                                system site-packages. We bake it into files/site-packages.
# These examples use pure-Python deps (humanize), so any interpreter works and no arm64 build is
# needed; a plugin with a COMPILED dep would build that wheel on an arm64 runner first (see u1-hw-camera).
#
# Requires: python3 with pip.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

for dir in "$REPO_DIR"/*/; do
  [ -f "${dir}manifest.json" ] || continue
  if [ -f "${dir}requirements.txt" ]; then
    mkdir -p "${dir}files/wheels"
    python3 -m pip download -r "${dir}requirements.txt" --only-binary=:all: -d "${dir}files/wheels"
    echo "Baked wheels for ${dir}"
  fi
  if [ -f "${dir}klipper_requirements.txt" ]; then
    mkdir -p "${dir}files/site-packages"
    python3 -m pip install --target "${dir}files/site-packages" -r "${dir}klipper_requirements.txt"
    echo "Baked site-packages for ${dir}"
  fi
done
