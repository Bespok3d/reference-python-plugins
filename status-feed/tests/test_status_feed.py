import sys
from pathlib import Path

import pytest

pytest.importorskip("humanize")
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "files" / "bin"))

import status_feed  # noqa: E402


def test_summarize_reports_state_and_filename() -> None:
    status = {
        "print_stats": {"state": "printing", "filename": "bracket.gcode", "print_duration": 3600.0},
        "display_status": {"progress": 0.42},
    }
    summary = status_feed.summarize(status)
    assert summary["state"] == "printing"
    assert summary["filename"] == "bracket.gcode"
    assert summary["progress"] == "42%"


def test_summarize_falls_back_to_virtual_sdcard_progress() -> None:
    status = {"print_stats": {"state": "printing"}, "virtual_sdcard": {"progress": 0.5}}
    assert status_feed.summarize(status)["progress"] == "50%"


def test_summarize_defaults_when_idle() -> None:
    summary = status_feed.summarize({})
    assert summary["state"] == "unknown"
    assert summary["progress"] == "0%"
