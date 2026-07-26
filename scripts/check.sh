#!/usr/bin/env bash
# This repo's own gate: it must pass from this repo's root, with no sibling repo cloned except
# lib_bespok3d. Exits non-zero on any failure.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The shared gate helpers and the detectors that enforce a workspace-wide rule live in one place.
# See lib_bespok3d/tooling/README.md. This is the only line that knows where they are.
B3D_TOOLING="${B3D_TOOLING:-$REPO_ROOT/lib_bespok3d/tooling}"
# lib_bespok3d is a submodule. A clone made without it leaves an empty directory here, so say what
# is actually wrong instead of letting every check below fail on a missing file.
if [ ! -f "$B3D_TOOLING/gate-lib.sh" ]; then
    echo "The shared gate helpers are missing: the lib_bespok3d submodule is not checked out." >&2
    echo "Run this once from the repo root, then try again:" >&2
    echo "  git submodule sync --recursive && git submodule update --init --recursive" >&2
    echo "See CONTRIBUTING.md for the full environment setup." >&2
    exit 1
fi

# shellcheck source=/dev/null
. "$B3D_TOOLING/gate-lib.sh"

cd "$REPO_ROOT" || exit 1

echo ""
echo "reference-python-plugins gate"

b3d_python_tools

# print-time-human vendors humanize under files/site-packages, so its own tree is the import path
# its tests and its type checks resolve against.
export PYTHONPATH="$REPO_ROOT/print-time-human/files/site-packages"

# That vendored tree is gitignored (baked into the package at publish), so a clean checkout, which
# is what CI gets, has no humanize: the status-feed test would importorskip it and never run,
# leaving the gate green on an untested plugin. Provision the plugin's own declared dependency into
# the tree PYTHONPATH resolves against so the test actually exercises the code. B3D_PY is the gate's
# tool interpreter, provisioned by b3d_python_tools above.
"$B3D_PY" -m pip install --quiet --target "$REPO_ROOT/print-time-human/files/site-packages" -r "$REPO_ROOT/status-feed/requirements.txt"

run_check "pytest (status-feed)"  pytest_in_dir "$REPO_ROOT/status-feed" tests
run_check "ruff (status-feed)"    ruff_in_dir "$REPO_ROOT/status-feed" files tests
run_check "ruff (print-time-human)" ruff_in_dir "$REPO_ROOT/print-time-human" files/klipper

unset PYTHONPATH

workflow_pinning_check "$REPO_ROOT"
em_dash_check "$REPO_ROOT"
shellcheck_repo "$REPO_ROOT"

gate_summary || exit 1
