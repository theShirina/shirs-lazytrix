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
    "ShirsLazyTrix_Trainer.lua",
    "ShirsLazyTrix_World.lua",
    "ShirsLazyTrix_UI.lua",
    "ShirsLazyTrix.lua",
]
TESTS = [
    "tests/test_engine.lua",
    "tests/test_controller.lua",
    "tests/test_trainer.lua",
    "tests/test_world.lua",
    "tests/test_stealth.lua",
    "tests/test_merchant.lua",
    "tests/test_repair.lua",
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
    "ShirsLazyTrix_Trainer.lua",
    "ShirsLazyTrix_World.lua",
    "ShirsLazyTrix_UI.lua",
    "docs/precedents.md",
    "scripts/build_release.py",
    "scripts/validate.py",
    "tests/test_build_release.py",
    "tests/test_controller.lua",
    "tests/test_trainer.lua",
    "tests/test_world.lua",
    "tests/test_stealth.lua",
    "tests/test_engine.lua",
    "tests/test_event_runtime.lua",
    "tests/test_event_structure.lua",
    "tests/test_merchant.lua",
    "tests/test_repair.lua",
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
    assert re.search(r"^## Version:\s*0\.0\.6\s*$", toc, re.MULTILINE), "TOC version must be 0.0.6"
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
    assert "turnInAttempts" in controller, "missing two-attempt turn-in fallback"
    assert "pendingTurnInSuccess" in controller, "turn-in fallback must wait for a reward attempt"
    assert controller.count("confirmMissingTurnIns(npc, active)") == 3, "both quest dialogs must confirm success from the same NPC list"
    assert "lastQuestLogTitles" not in controller, "title-only quest-log success evidence is ambiguous"
    assert "GetQuestLogTitle" not in controller, "NPC-scoped guards must not clear from title-only quest-log data"
    confirmation_helper = controller.split("local function confirmMissingTurnIns", 1)[1].split(
        "local function turnInAttemptAvailable", 1
    )[0]
    assert "incompleteSeen" not in confirmation_helper, "quest-list omission must not clear the incomplete latch"
    for removed in ("InstallRewardHook", "RememberTurnIn", "ObserveAvailable", "IsRepeatable"):
        assert removed not in controller, f"removed learner behavior remains: {removed}"

    engine = (ROOT / "ShirsLazyTrix_Engine.lua").read_text(encoding="utf-8")
    assert "repeatable" not in engine.lower(), "engine must not classify quest recurrence"

    trainer = (ROOT / "ShirsLazyTrix_Trainer.lua").read_text(encoding="utf-8")
    for token in (
        "TRAINER_ROWS = 18",
        "TRAINER_LIST_HEIGHT = 296",
        "CLASS_FRAME_HEIGHT = 624",
        "TRADE_FRAME_HEIGHT = 640",
        'RegisterEvent("TRAINER_SHOW")',
        'RegisterEvent("TRAINER_UPDATE")',
        'RegisterEvent("TRAINER_CLOSED")',
        "pcall(GetNumTrainerServices)",
        "pcall(GetTrainerServiceInfo, index)",
        "pcall(GetTrainerServiceCost, index)",
        'serviceType == "available"',
        "validPointCost(cp1)",
        "validPointCost(cp2)",
        "pcall(BuyTrainerService, index)",
        "HandleTrainerOnUpdate(elapsed)",
        "TRAINER_MAX_RETRIES = 2",
        "TRAINER_TIMEOUT_SECONDS = 3",
        "money == lastPurchaseMoney",
        "buildTrainAllSnapshot()",
        "seen[info.identity]",
        "findSnapshotService(entry.identity)",
        "moneyCost ~= entry.money",
        "trainAllSubmitting",
        "trainerVisible()",
        "pcall(SkinCollapseButton, button)",
        'setPoint(button, "TOPLEFT", previous, "BOTTOMLEFT", 0, 0)',
        'setPoint(ClassTrainerDetailScrollFrame, "TOPLEFT", ClassTrainerListScrollFrame, "BOTTOMLEFT", 0, -8)',
        "GetGossipOptions()",
        'options[i] == "trainer"',
        "pcall(SelectGossipOption, found)",
        "held == true or held == 1",
        "ClassTrainer_SetToTradeSkillTrainer = function()",
        "ClassTrainer_SetToClassTrainer = function()",
        'CreateFrame("Button", name, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")',
    ):
        assert token in trainer, f"trainer feature is missing exact-client behavior: {token}"
    assert trainer.count("pcall(BuyTrainerService, index)") == 1, "Train All must have one guarded purchase call"
    assert "hooksecurefunc" not in trainer, "trainer feature must not use the later secure-hook API"
    assert "SetWidth(714)" not in trainer, "trainer layout must preserve stock width"
    assert 'CreateFrame("Frame", "ShirsLazyTrixTrainerDetailsBackdrop"' not in trainer, "trainer detail pane must remain below the list"
    assert "MAX_COPPER = 2147483647" in trainer, "trainer cost guard must use the Vanilla signed range"

    merchant = (ROOT / "ShirsLazyTrix_Merchant.lua").read_text(encoding="utf-8")
    assert merchant.count("UseContainerItem(") == 1, "merchant module must have one revalidated sale call"
    assert "quality ~= 0" in merchant, "merchant sale must reject every non-gray quality"
    assert "GetContainerItemInfo(entry.bag, entry.slot)" in merchant, "merchant sale must revalidate the live slot"
    for token in ("CanMerchantRepair()", "GetRepairAllCost()", "GetMoney()", "RepairAllItems()"):
        assert token in merchant, f"automatic repair path is missing exact-client API: {token}"
    assert merchant.count("RepairAllItems()") == 1, "automatic repair must have one guarded submission call"
    assert "validCopper(cost, false)" in merchant, "repair cost must pass the exact-runtime finite copper guard"
    assert "validCopper(availableMoney, true)" in merchant, "available money must pass the exact-runtime finite copper guard"
    assert "MAX_COPPER = 2147483647" in merchant, "finite copper guard must use the Vanilla signed range"
    assert "value == true or value == 1" in merchant, "repair eligibility must accept only Vanilla boolean forms"
    assert merchant.count("apiTrue(") == 3, "both repair eligibility values must use the strict boolean guard"
    for removed in ("junkItems", "ToggleJunk", "SetJunkMark", "Sell Junk", "ShouldShowMerchantSellButton"):
        assert removed not in merchant, f"manual junk or merchant-button behavior remains: {removed}"

    world = (ROOT / "ShirsLazyTrix_World.lua").read_text(encoding="utf-8")
    for token in ("IsInInstance()", "AcceptResurrect()", 'StaticPopup_Hide("RESURRECT_NO_TIMER")'):
        assert token in world, f"open-world resurrection path is missing exact-client API: {token}"
    assert world.count("AcceptResurrect()") == 1, "resurrection path must have one guarded acceptance call"
    assert "inside == nil or inside == false or inside == 0" in world, "open-world check must support exact Vanilla outside forms"
    assert 'instanceType ~= nil and instanceType ~= "none"' in world, "contradictory instance types must fail closed"
    assert "RepopMe" not in world, "pending-resurrection acceptance must never release the corpse"
    for token in (
        '"You gain Stealth."',
        '"You gain Lesser Invisibility."',
        '"You gain Invisibility."',
        '"Fire Shield"',
        '"Fire Shield IV"',
        '"Oil of Immolation"',
        '"Immolation Aura"',
        '"spell_fire_immolation"',
        'GetPlayerBuff(slot, "HELPFUL")',
        "GetPlayerBuffTexture(buffIndex)",
        "CancelPlayerBuff(buffIndex)",
    ):
        assert token in world, f"stealth immolation cleanup is missing exact-client behavior: {token}"
    assert "for slot = 31, 0, -1 do" in world, "buff cancellation must scan from the highest slot down"
    assert "SendChatMessage" not in world, "stealth cleanup must not send chat output"
    assert 'CancelBuff("' not in world, "stealth cleanup must not depend on SuperMacro"

    ui = (ROOT / "ShirsLazyTrix_UI.lua").read_text(encoding="utf-8")
    for key in ("turnIn", "pickUp", "automationOnShift", "autoSellGray", "autoRepairAll", "autoAcceptOpenWorldRes", "autoRemoveImmolationOnStealth", "enhanceTrainers", "autoOpenTrainers"):
        assert ui.count(f'"{key}"') == 1, f"settings key must appear once in UI: {key}"
    assert "turnInOnShift" not in ui, "retired turn-in-only Shift key remains in UI"
    assert "repeatable" not in ui.lower(), "UI must not expose recurrence controls"
    assert "junk" not in ui.lower(), "UI must not expose junk marking or a junk button"
    assert "When enabled, Shift triggers both pickup and turn-in." in ui, "UI must explain unified Shift behavior"
    assert "Sells gray-quality items only." in ui, "UI must state the gray-only merchant boundary"
    assert "Automatically repair all gear at repair vendors" in ui, "UI must expose explicit automatic repair wording"
    assert "Automatically accept open-world resurrection requests" in ui, "UI must expose the open-world resurrection boundary"
    assert "Remove immolation effects on stealth or invisibility" in ui, "UI must expose stealth immolation cleanup"
    assert "Expand trainer windows and add Train All" in ui, "UI must expose trainer enhancement"
    assert "Automatically open trainer services" in ui, "UI must expose automatic trainer gossip"

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
