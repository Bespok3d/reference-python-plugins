#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 unlucio and the Bespok3d contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
# This repo's own gate: it must pass from this repo's root, with no sibling repo cloned except
# lib_bespok3d. Exits non-zero on any failure.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The shared gate helpers and the detectors that enforce a workspace-wide rule live in one place.
# See lib_bespok3d/tooling/README.md. This is the only line that knows where they are.
B3D_TOOLING="${B3D_TOOLING:-$REPO_ROOT/lib_bespok3d/tooling}"
# lib_bespok3d is a submodule. A clone made without it leaves an empty directory here, so say what
# is actually wrong instead of letting every check below fail on a missing file.
if [ ! -f "$B3D_TOOLING/gate-lib.sh" ] || [ ! -f "$B3D_TOOLING/release-trigger-detector.mjs" ] || [ ! -f "$B3D_TOOLING/manifest-origin-detector.mjs" ]; then
    echo "The shared gate helpers are missing or older than the checks this gate runs:" >&2
    echo "the lib_bespok3d submodule is not checked out, or is pinned to an older commit." >&2
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

release_trigger_check "$REPO_ROOT"
manifest_origin_check "$REPO_ROOT"
workflow_pinning_check "$REPO_ROOT"
em_dash_check "$REPO_ROOT"
shellcheck_repo "$REPO_ROOT"


# Per-file REUSE compliance: every file is covered by a copyright and licence statement, its own
# header or the REUSE.toml block, and every licence a file names has its text in LICENSES/.
# Whole-project `reuse lint` is not used here, because LICENSES/ also carries the texts for
# third-party code that the built package conveys but that is not committed in this repo (see
# REUSE.toml), which that mode reports as unused. The file list is tracked plus not-yet-committed
# files, so a newly vendored file is checked before it is committed rather than after, and a
# not-yet-committed rename does not point the linter at a path that no longer exists. `reuse` is not
# a workspace dependency: an installed one is used when present, otherwise uv runs it from cache, and
# a machine with neither reports the check as skipped rather than as passed.
# shellcheck disable=SC2329  # run_check invokes this by name, which shellcheck cannot follow.
run_reuse_lint() {
    if command -v reuse > /dev/null 2>&1; then
        reuse "$@"
    else
        uvx --quiet --from 'reuse[charset-normalizer]' reuse "$@"
    fi
}

# shellcheck disable=SC2329  # run_check invokes this by name, which shellcheck cannot follow.
reuse_per_file_check() {
    local licensed_paths=()
    local candidate_path
    local licensed_count=0
    while IFS= read -r -d '' candidate_path; do
        if [ -f "$candidate_path" ]; then
            licensed_paths+=("$candidate_path")
            licensed_count=$((licensed_count + 1))
        fi
    done < <(git ls-files -z --cached --others --exclude-standard)
    if [ "$licensed_count" -eq 0 ]; then
        return 0
    fi
    run_reuse_lint lint-file "${licensed_paths[@]}"
}

if command -v reuse > /dev/null 2>&1 || command -v uvx > /dev/null 2>&1; then
    run_check "reuse (per-file licensing)" reuse_per_file_check
else
    skip_check "reuse (per-file licensing)" "install reuse, or install uv so it can be run from cache"
fi

gate_summary || exit 1
