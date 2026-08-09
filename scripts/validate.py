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
    "ShirsLazyTrix_Merchant.lua",
    "ShirsLazyTrix_Controller.lua",
    "ShirsLazyTrix_UI.lua",
    "ShirsLazyTrix.lua",
]
TESTS = [
    "tests/test_engine.lua",
    "tests/test_controller.lua",
    "tests/test_merchant.lua",
    "tests/test_ui_structure.lua",
    "tests/test_ui_runtime.lua",
    "tests/test_event_structure.lua",
    "tests/test_event_runtime.lua",
]
PYTHON_TESTS = [
    "tests/test_build_release.py",
]
TOC_ORDER = LUA_FILES
PUBLIC_FILES = {
    ".gitattributes",
    ".github/workflows/validate.yml",
    ".gitignore",
    "CHANGELOG.md",
    "LICENSE",
    "LazyTrixIcon.tga",
    "README.md",
    "README.txt",
    "ShirsLazyTrix.lua",
    "ShirsLazyTrix.toc",
    "ShirsLazyTrix_Controller.lua",
    "ShirsLazyTrix_Engine.lua",
    "ShirsLazyTrix_Merchant.lua",
    "ShirsLazyTrix_UI.lua",
    "docs/precedents.md",
    "scripts/build_release.py",
    "scripts/validate.py",
    "tests/test_build_release.py",
    "tests/test_controller.lua",
    "tests/test_engine.lua",
    "tests/test_event_runtime.lua",
    "tests/test_event_structure.lua",
    "tests/test_merchant.lua",
    "tests/test_ui_structure.lua",
    "tests/test_ui_runtime.lua",
}


def run(command: list[str]) -> None:
    flags = 0x08000000 if sys.platform == "win32" else 0
    subprocess.run(command, cwd=ROOT, check=True, creationflags=flags)


def validate_public_boundary() -> None:
    actual = {
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and ".git" not in path.parts
        and "dist" not in path.parts
        and "__pycache__" not in path.parts
    }
    assert actual == PUBLIC_FILES, f"unexpected public files: {sorted(actual ^ PUBLIC_FILES)}"

    forbidden = (
        b"c:" + b"/users/",
        b"c:" + b"\\users\\",
        b"e:" + b"/hermes",
        b"e:" + b"\\hermes",
        b"appdata" + b"/local/hermes",
        b"discord.com/api/" + b"webhooks",
        b"gh" + b"o_",
    )
    for name in sorted(actual):
        data = (ROOT / name).read_bytes()
        if name != "LazyTrixIcon.tga":
            assert b"\0" not in data, f"unexpected binary file: {name}"
        lowered = data.lower()
        for token in forbidden:
            assert token not in lowered, f"private token or path in {name}: {token!r}"


def validate_source() -> None:
    validate_public_boundary()
    toc = (ROOT / "ShirsLazyTrix.toc").read_text(encoding="utf-8")
    assert re.search(r"^## Interface:\s*11200\s*$", toc, re.MULTILINE), "TOC interface must be 11200"
    assert re.search(r"^## Version:\s*0\.0\.2\s*$", toc, re.MULTILINE), "TOC version must be 0.0.2"
    assert re.search(r"^## SavedVariables:\s*ShirsLazyTrixDB\s*$", toc, re.MULTILINE), "SavedVariables mismatch"

    entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("##")]
    assert entries == TOC_ORDER, f"unexpected TOC load order: {entries}"
    for name in entries:
        assert (ROOT / name).is_file(), f"missing TOC file: {name}"

    controller = (ROOT / "ShirsLazyTrix_Controller.lua").read_text(encoding="utf-8")
    assert "IsQuestCompletable()" in controller, "missing incomplete-quest guard"
    assert "IsShiftKeyDown()" in controller, "missing physical Shift bypass"
    assert controller.count("CompleteQuest()") == 1, "turn-in must have one guarded completion call"
    assert controller.count("AcceptQuest()") == 1, "pickup must have one guarded acceptance call"
    assert "GetQuestReward(count)" in controller, "reward choice must use bounded count"
    for removed in ("InstallRewardHook", "RememberTurnIn", "ObserveAvailable", "IsRepeatable"):
        assert removed not in controller, f"removed learner behavior remains: {removed}"

    engine = (ROOT / "ShirsLazyTrix_Engine.lua").read_text(encoding="utf-8")
    assert "repeatable" not in engine.lower(), "engine must not classify quest recurrence"

    merchant = (ROOT / "ShirsLazyTrix_Merchant.lua").read_text(encoding="utf-8")
    assert merchant.count("UseContainerItem(") == 1, "merchant module must have one revalidated sale call"
    assert "quality ~= 0" in merchant, "merchant sale must reject every non-gray quality"
    assert "GetContainerItemInfo(entry.bag, entry.slot)" in merchant, "merchant sale must revalidate the live slot"
    for removed in ("junkItems", "ToggleJunk", "SetJunkMark", "Sell Junk", "ShouldShowMerchantSellButton"):
        assert removed not in merchant, f"manual junk or merchant-button behavior remains: {removed}"

    ui = (ROOT / "ShirsLazyTrix_UI.lua").read_text(encoding="utf-8")
    for key in ("turnIn", "pickUp", "automationOnShift", "autoSellGray"):
        assert ui.count(f'"{key}"') == 1, f"settings key must appear once in UI: {key}"
    assert "turnInOnShift" not in ui, "retired turn-in-only Shift key remains in UI"
    assert "repeatable" not in ui.lower(), "UI must not expose recurrence controls"
    assert "junk" not in ui.lower(), "UI must not expose junk marking or a junk button"
    assert "When enabled, Shift triggers both pickup and turn-in." in ui, "UI must explain unified Shift behavior"
    assert "Sells gray-quality items only." in ui, "UI must state the gray-only merchant boundary"

    icon = (ROOT / "LazyTrixIcon.tga").read_bytes()
    pixel_end = 18 + (64 * 64 * 4)
    assert len(icon) in (pixel_end, pixel_end + 26), "LazyTrix icon has unexpected TGA payload size"
    if len(icon) == pixel_end + 26:
        assert icon[-26:] == (b"\0" * 8) + b"TRUEVISION-XFILE.\0", "LazyTrix icon has an invalid TGA 2.0 footer"
    assert icon[0] == 0 and icon[1] == 0 and icon[2] == 2, "LazyTrix icon must be uncompressed true-color TGA"
    assert int.from_bytes(icon[12:14], "little") == 64, "LazyTrix icon width must be 64"
    assert int.from_bytes(icon[14:16], "little") == 64, "LazyTrix icon height must be 64"
    assert icon[16] == 32, "LazyTrix icon must use 32-bit pixels"

    for name in ("README.md", "README.txt", "CHANGELOG.md", "docs/precedents.md"):
        text = (ROOT / name).read_text(encoding="utf-8")
        assert "repeatable" not in text.lower(), f"obsolete recurrence wording remains in {name}"

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
    for name in PYTHON_TESTS:
        run([sys.executable, str(ROOT / name)])
    print("validation: PASS")


if __name__ == "__main__":
    main()
