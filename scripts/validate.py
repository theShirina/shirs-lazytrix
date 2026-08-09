#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA_FILES = [
    "ShirsLazyTrix_Engine.lua",
    "ShirsLazyTrix_Controller.lua",
    "ShirsLazyTrix_UI.lua",
    "ShirsLazyTrix.lua",
]
TESTS = [
    "tests/test_engine.lua",
    "tests/test_controller.lua",
    "tests/test_ui_structure.lua",
    "tests/test_event_structure.lua",
]
TOC_ORDER = LUA_FILES


def run(command: list[str]) -> None:
    flags = 0x08000000 if sys.platform == "win32" else 0
    subprocess.run(command, cwd=ROOT, check=True, creationflags=flags)


def validate_source() -> None:
    toc = (ROOT / "ShirsLazyTrix.toc").read_text(encoding="utf-8")
    assert re.search(r"^## Interface:\s*11200\s*$", toc, re.MULTILINE), "TOC interface must be 11200"
    assert re.search(r"^## Version:\s*0\.0\.1\s*$", toc, re.MULTILINE), "TOC version must be 0.0.1"
    assert re.search(r"^## SavedVariables:\s*ShirsLazyTrixDB\s*$", toc, re.MULTILINE), "SavedVariables mismatch"

    entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("##")]
    assert entries == TOC_ORDER, f"unexpected TOC load order: {entries}"
    for name in entries:
        assert (ROOT / name).is_file(), f"missing TOC file: {name}"

    controller = (ROOT / "ShirsLazyTrix_Controller.lua").read_text(encoding="utf-8")
    assert "IsQuestCompletable()" in controller, "missing incomplete-quest guard"
    assert controller.count("CompleteQuest()") == 1, "turn-in must have one guarded completion call"
    assert "GetQuestReward(count)" in controller, "reward choice must use bounded count"

    ui = (ROOT / "ShirsLazyTrix_UI.lua").read_text(encoding="utf-8")
    for key in ("turnInNormal", "pickUpNormal", "turnInRepeatable", "pickUpRepeatable"):
        assert ui.count(f'"{key}"') == 1, f"settings key must appear once in UI: {key}"

    combined = "\n".join((ROOT / name).read_text(encoding="utf-8") for name in LUA_FILES)
    forbidden = ("C_QuestLog", "QUEST_ACCEPT_CONFIRM", "QUEST_AUTOCOMPLETE", "hooksecurefunc")
    for token in forbidden:
        assert token not in combined, f"later-client API is forbidden: {token}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lua", required=True)
    parser.add_argument("--luac", required=True)
    args = parser.parse_args()

    validate_source()
    for name in LUA_FILES:
        run([args.luac, "-p", str(ROOT / name)])
    for name in TESTS:
        run([args.lua, str(ROOT / name), str(ROOT)])
    print("validation: PASS")


if __name__ == "__main__":
    main()
