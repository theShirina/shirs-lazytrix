-- Shir's LazyTrix controller tests for Lua 5.0.3

local root = arg and arg[1] or "."
dofile(root .. "/ShirsLazyTrix_Engine.lua")

local calls = {}
local active = {}
local available = {}
local gossipActive = {}
local gossipAvailable = {}
local title = ""
local completable = false
local choices = 0
local npc = "Quest Giver"
local shiftDown = false
local questLog = {}

local function resetCalls()
  calls = {}
end

local function countCalls(name)
  local count = 0
  local i
  for i = 1, table.getn(calls) do
    if calls[i][1] == name then count = count + 1 end
  end
  return count
end

local function lastCall(name)
  local i
  for i = table.getn(calls), 1, -1 do
    if calls[i][1] == name then return calls[i] end
  end
  return nil
end

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

function UnitName(unit)
  if unit == "player" then return "Shirina" end
  return npc
end
function GetRealmName() return "Icecrown" end
function IsShiftKeyDown() return shiftDown and 1 or nil end
function GetNumActiveQuests() return table.getn(active) end
function GetActiveTitle(index) return active[index].title, active[index].complete end
function GetNumAvailableQuests() return table.getn(available) end
function GetAvailableTitle(index) return available[index].title end
function SelectActiveQuest(index) table.insert(calls, { "SelectActiveQuest", index }) end
function SelectAvailableQuest(index) table.insert(calls, { "SelectAvailableQuest", index }) end
function GetGossipActiveQuests() return unpack(gossipActive) end
function GetGossipAvailableQuests() return unpack(gossipAvailable) end
function SelectGossipActiveQuest(index) table.insert(calls, { "SelectGossipActiveQuest", index }) end
function SelectGossipAvailableQuest(index) table.insert(calls, { "SelectGossipAvailableQuest", index }) end
function GetTitleText() return title end
function IsQuestCompletable() return completable end
function AcceptQuest() table.insert(calls, { "AcceptQuest" }) end
function CompleteQuest() table.insert(calls, { "CompleteQuest" }) end
function GetNumQuestChoices() return choices end
function GetQuestReward(index) table.insert(calls, { "GetQuestReward", index }) end
function GetNumQuestLogEntries() return table.getn(questLog) end
function GetQuestLogTitle(index)
  local entry = questLog[index]
  return entry.title, entry.level, entry.tag, entry.isHeader, entry.isCollapsed, entry.complete
end

dofile(root .. "/ShirsLazyTrix_Controller.lua")

ShirsLazyTrixDB = nil
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.turnIn, true, "turn-in default")
assertEqual(ShirsLazyTrixDB.pickUp, true, "pickup default")
assertEqual(ShirsLazyTrixDB.automationOnShift, false, "Shift-required automation default")
assertEqual(ShirsLazyTrixDB.autoSellGray, false, "automatic gray sale default")
assertEqual(ShirsLazyTrixDB.autoRepairAll, false, "automatic repair default")
assertEqual(ShirsLazyTrixDB.autoAcceptOpenWorldRes, false, "open-world resurrection default")
assertEqual(ShirsLazyTrixDB.autoRemoveImmolationOnStealth, false, "stealth immolation cleanup default")
assertEqual(ShirsLazyTrixDB.expandTrainers, false, "expanded trainer default")
assertEqual(ShirsLazyTrixDB.trainAll, false, "Train All default")
assertEqual(ShirsLazyTrixDB.enhanceTrainers, nil, "retired combined trainer key default")
assertEqual(ShirsLazyTrixDB.autoOpenTrainers, false, "automatic trainer gossip default")
assertEqual(ShirsLazyTrixDB.showCooldownPanel, false, "profession cooldown panel default")
assertEqual(ShirsLazyTrixDB.cooldownPanelLocked, false, "cooldown panel lock default")
assertEqual(ShirsLazyTrixDB.hideCooldownPanelInCombat, false, "cooldown combat-hide default")
assertEqual(ShirsLazyTrixDB.notifyOtherMooncloth, true, "other-character Mooncloth reminder default")
assertEqual(ShirsLazyTrixDB.notifyOtherArcanite, true, "other-character Arcanite reminder default")
assertEqual(ShirsLazyTrixDB.notifyOtherSalt, true, "other-character Salt Shaker reminder default")
assertEqual(ShirsLazyTrixDB.showItemIDs, false, "item-ID tooltip default")
assertEqual(ShirsLazyTrixDB.expandLootRows, true, "expanded loot rows default")
assertEqual(ShirsLazyTrixDB.lootRows, 4, "stock loot row default")
assertEqual(ShirsLazyTrixDB.consolidateMinimapButtons, false, "minimap collector default")
assertEqual(ShirsLazyTrixDB.minimapButtonSize, 24, "collected minimap button size default")
if type(ShirsLazyTrixDB.cooldownsByCharacter) ~= "table" then error("character cooldown table default missing", 2) end
assertEqual(ShirsLazyTrixDB.minimapAngle, 220, "minimap angle default")

ShirsLazyTrixDB = {
  showCooldownPanel = true,
  cooldownsByCharacter = { ["Realm\031Character"] = { mooncloth = { known = true, readyAt = 123 } } },
  cooldownPanelPosition = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 5, y = -7 },
  cooldownPanelLocked = true,
  hideCooldownPanelInCombat = true,
  notifyOtherMooncloth = false,
  notifyOtherArcanite = true,
  notifyOtherSalt = false,
  showItemIDs = true,
  lootRows = 9,
  consolidateMinimapButtons = true,
  minimapButtonSize = 28,
}
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.showCooldownPanel, true, "profession cooldown panel choice is preserved")
assertEqual(ShirsLazyTrixDB.cooldownsByCharacter["Realm\031Character"].mooncloth.readyAt, 123, "character cooldown state is preserved")
assertEqual(ShirsLazyTrixDB.cooldownPanelPosition.x, 5, "cooldown panel position is preserved")
assertEqual(ShirsLazyTrixDB.cooldownPanelLocked, true, "cooldown panel lock is preserved")
assertEqual(ShirsLazyTrixDB.hideCooldownPanelInCombat, true, "cooldown combat-hide choice is preserved")
assertEqual(ShirsLazyTrixDB.notifyOtherMooncloth, false, "Mooncloth reminder choice is preserved")
assertEqual(ShirsLazyTrixDB.notifyOtherArcanite, true, "Arcanite reminder choice is preserved")
assertEqual(ShirsLazyTrixDB.notifyOtherSalt, false, "Salt Shaker reminder choice is preserved")
assertEqual(ShirsLazyTrixDB.showItemIDs, true, "item-ID tooltip choice is preserved")
assertEqual(ShirsLazyTrixDB.lootRows, 9, "stock loot row choice is preserved")
assertEqual(ShirsLazyTrixDB.consolidateMinimapButtons, true, "minimap collector choice is preserved")
assertEqual(ShirsLazyTrixDB.minimapButtonSize, 28, "collected minimap button size choice is preserved")

ShirsLazyTrixDB = { enhanceTrainers = true }
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.expandTrainers, true, "legacy trainer setting migrates to expansion")
assertEqual(ShirsLazyTrixDB.trainAll, true, "legacy trainer setting migrates to Train All")
assertEqual(ShirsLazyTrixDB.enhanceTrainers, nil, "legacy trainer setting is removed")

ShirsLazyTrixDB = { expandTrainers = true, trainAll = false, enhanceTrainers = false }
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.expandTrainers, true, "independent expansion setting is preserved")
assertEqual(ShirsLazyTrixDB.trainAll, false, "independent Train All setting is preserved")
assertEqual(ShirsLazyTrixDB.enhanceTrainers, nil, "stale combined trainer key is removed")

ShirsLazyTrixDB = {
  turnInNormal = false,
  pickUpNormal = true,
  turnInRepeatable = true,
  pickUpRepeatable = true,
  repeatable = { old = true },
  repeatableByCharacter = { old = true },
  turnInOnShift = true,
  autoSellGray = "invalid",
  autoRepairAll = "invalid",
  autoAcceptOpenWorldRes = "invalid",
  autoRemoveImmolationOnStealth = "invalid",
  enhanceTrainers = "invalid",
  autoOpenTrainers = "invalid",
  showCooldownPanel = "invalid",
  cooldownPanelLocked = "invalid",
  hideCooldownPanelInCombat = "invalid",
  notifyOtherMooncloth = "invalid",
  notifyOtherArcanite = "invalid",
  notifyOtherSalt = "invalid",
  showItemIDs = "invalid",
  cooldownsByCharacter = "invalid",
  cooldownPanelPosition = "invalid",
  lootRows = 0 / 0,
  consolidateMinimapButtons = "invalid",
  minimapButtonSize = 0 / 0,
  minimapAngle = 0 / 0,
}
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.turnIn, false, "old normal turn-in setting migrates")
assertEqual(ShirsLazyTrixDB.pickUp, true, "old normal pickup setting migrates")
assertEqual(ShirsLazyTrixDB.automationOnShift, true, "temporary turn-in-only Shift setting migrates")
assertEqual(ShirsLazyTrixDB.autoSellGray, false, "invalid automatic gray sale setting repairs")
assertEqual(ShirsLazyTrixDB.autoRepairAll, false, "invalid automatic repair setting repairs")
assertEqual(ShirsLazyTrixDB.autoAcceptOpenWorldRes, false, "invalid open-world resurrection setting repairs")
assertEqual(ShirsLazyTrixDB.autoRemoveImmolationOnStealth, false, "invalid stealth immolation cleanup setting repairs")
assertEqual(ShirsLazyTrixDB.expandTrainers, false, "invalid expanded trainer setting repairs")
assertEqual(ShirsLazyTrixDB.trainAll, false, "invalid Train All setting repairs")
assertEqual(ShirsLazyTrixDB.enhanceTrainers, nil, "invalid combined trainer key is removed")
assertEqual(ShirsLazyTrixDB.autoOpenTrainers, false, "invalid automatic trainer gossip setting repairs")
assertEqual(ShirsLazyTrixDB.showCooldownPanel, false, "invalid profession cooldown panel setting repairs")
assertEqual(ShirsLazyTrixDB.cooldownPanelLocked, false, "invalid cooldown panel lock repairs")
assertEqual(ShirsLazyTrixDB.hideCooldownPanelInCombat, false, "invalid cooldown combat-hide setting repairs")
assertEqual(ShirsLazyTrixDB.notifyOtherMooncloth, true, "invalid Mooncloth reminder setting repairs")
assertEqual(ShirsLazyTrixDB.notifyOtherArcanite, true, "invalid Arcanite reminder setting repairs")
assertEqual(ShirsLazyTrixDB.notifyOtherSalt, true, "invalid Salt Shaker reminder setting repairs")
assertEqual(ShirsLazyTrixDB.showItemIDs, false, "invalid item-ID tooltip setting repairs")
if type(ShirsLazyTrixDB.cooldownsByCharacter) ~= "table" then error("invalid character cooldown table was not repaired", 2) end
assertEqual(ShirsLazyTrixDB.cooldownPanelPosition, nil, "invalid cooldown panel position is removed")
assertEqual(ShirsLazyTrixDB.lootRows, 4, "invalid NaN loot rows repair")
assertEqual(ShirsLazyTrixDB.consolidateMinimapButtons, false, "invalid minimap collector repairs")
assertEqual(ShirsLazyTrixDB.minimapButtonSize, 24, "invalid collected minimap button size repairs")
assertEqual(ShirsLazyTrixDB.turnInOnShift, nil, "temporary turn-in-only Shift key is removed")
assertEqual(ShirsLazyTrixDB.minimapAngle, 220, "invalid minimap angle repairs")
assertEqual(ShirsLazyTrixDB.turnInNormal, nil, "old normal turn-in key removed")
assertEqual(ShirsLazyTrixDB.pickUpNormal, nil, "old normal pickup key removed")
assertEqual(ShirsLazyTrixDB.turnInRepeatable, nil, "old repeatable turn-in key removed")
assertEqual(ShirsLazyTrixDB.pickUpRepeatable, nil, "old repeatable pickup key removed")
assertEqual(ShirsLazyTrixDB.repeatable, nil, "old shared learner removed")
assertEqual(ShirsLazyTrixDB.repeatableByCharacter, nil, "old character learner removed")
ShirsLazyTrixDB.automationOnShift = "invalid"
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.automationOnShift, false, "invalid Shift-required automation setting repairs")
ShirsLazyTrixDB.turnIn = true
ShirsLazyTrixDB.pickUp = true

active = {
  { title = "Incomplete", complete = false },
  { title = "Complete", complete = true },
}
available = { { title = "Available" } }
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectActiveQuest")[2], 2, "completed greeting quest is prioritized")
assertEqual(countCalls("SelectAvailableQuest"), 0, "pickup waits for turn-in")

shiftDown = true
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 0, "Shift bypasses greeting turn-in selection")
assertEqual(countCalls("SelectAvailableQuest"), 0, "Shift bypasses greeting pickup selection")

gossipActive = { "Complete Gossip Quest", 30 }
gossipAvailable = { "Available Gossip Quest", 30 }
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 0, "Shift bypasses gossip turn-in selection")
assertEqual(countCalls("SelectGossipAvailableQuest"), 0, "Shift bypasses gossip pickup selection")

shiftDown = false
active = { { title = "Legacy Active", complete = nil } }
available = { { title = "Available" } }
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectActiveQuest")[2], 1, "legacy active quest is inspected first")

title = "Legacy Active"
completable = false
resetCalls()
ShirsLazyTrix.HandleQuestProgress()
assertEqual(countCalls("CompleteQuest"), 0, "incomplete quest is never completed")

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectAvailableQuest")[2], 1, "inspected incomplete quest does not block pickup")
assertEqual(countCalls("SelectActiveQuest"), 0, "inspected incomplete quest stays skipped")

questLog = { { title = "Legacy Active", complete = false } }
gossipActive = { "Legacy Active", 30 }
gossipAvailable = {}
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 0, "closing the quest frame must not retry an item-gated quest")

ShirsLazyTrix.HandleQuestLogUpdate()
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 0, "incomplete quest-log state keeps failed turn-in blocked")

questLog[1].complete = true
ShirsLazyTrix.HandleQuestLogUpdate()
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 0, "same-title quest-log completion must not clear an NPC-scoped guard")

active = { { title = "Legacy Active", complete = true } }
gossipActive = {}
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectActiveQuest")[2], 1, "same NPC dialog completion clears its incomplete guard")

questLog = {}
ShirsLazyTrix.HandleQuestLogUpdate()

shiftDown = true
title = "Manual Pickup"
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 0, "Shift bypasses automatic pickup")

completable = true
resetCalls()
ShirsLazyTrix.HandleQuestProgress()
assertEqual(countCalls("CompleteQuest"), 0, "Shift bypasses automatic turn-in progress")

choices = 1
resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(countCalls("GetQuestReward"), 0, "Shift bypasses automatic reward submission")

shiftDown = false
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 1, "pickup resumes when Shift is released")

resetCalls()
ShirsLazyTrix.HandleQuestProgress()
assertEqual(countCalls("CompleteQuest"), 1, "turn-in resumes when Shift is released")

resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(lastCall("GetQuestReward")[2], 1, "single reward is selected")

choices = 2
resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(countCalls("GetQuestReward"), 0, "multiple rewards wait for player")

-- A custom quest can report completable while refusing the submitted reward.
-- Allow two selections, block the third, and reset only after reward submission
-- is followed by the title disappearing from the same NPC's active quest list.
ShirsLazyTrix.incompleteSeen = {}
ShirsLazyTrix.turnInAttempts = {}
ShirsLazyTrix.pendingTurnInSuccess = {}
npc = "Custom Quest Giver"
title = "Misreported Custom Quest"
active = { { title = title, complete = true } }
available = {}
questLog = { { title = title, complete = true } }
completable = true
choices = 1

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 1, "first custom quest turn-in attempt is allowed")
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()
ShirsLazyTrix.HandleQuestLogUpdate()

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 1, "second custom quest turn-in attempt is allowed")
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()
ShirsLazyTrix.HandleQuestLogUpdate()

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 0, "third failed custom quest turn-in attempt is blocked")

active = {}
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
active = { { title = title, complete = true } }
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 1, "same-NPC active-list disappearance clears the retry fallback")

ShirsLazyTrix.turnInAttempts = {}
ShirsLazyTrix.pendingTurnInSuccess = {}
npc = "Mixed Dialog Quest Giver"
title = "Mixed Dialog Custom Quest"
active = { { title = title, complete = true } }
gossipActive = { title, 30 }
questLog = { { title = title, complete = true } }

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 1, "mixed-dialog first greeting attempt is allowed")
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()
ShirsLazyTrix.HandleQuestLogUpdate()

resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 1, "mixed-dialog second gossip attempt is allowed")
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()
ShirsLazyTrix.HandleQuestLogUpdate()

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 0, "greeting and gossip attempts share the two-try limit")

ShirsLazyTrix.turnInAttempts = {}
ShirsLazyTrix.pendingTurnInSuccess = {}
ShirsLazyTrix.lastQuestLogTitles = {}
npc = "Logless Custom Quest Giver"
title = "Logless Custom Quest"
active = { { title = title, complete = true } }
gossipActive = {}
questLog = { { title = title, complete = true } }

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()
ShirsLazyTrix.HandleQuestLogUpdate()
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()
ShirsLazyTrix.HandleQuestLogUpdate()
questLog = {}
ShirsLazyTrix.HandleQuestLogUpdate()
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 0, "an unrelated same-title log transition must not reset a logless NPC quest")

-- An older reward-attempt latch must never clear a newer incomplete latch.
ShirsLazyTrix.incompleteSeen = {}
ShirsLazyTrix.turnInAttempts = {}
ShirsLazyTrix.pendingTurnInSuccess = {}
npc = "Interleaved Custom Quest Giver"
title = "Interleaved Custom Quest"
active = { { title = title, complete = true } }
gossipActive = {}
questLog = {}
completable = true
choices = 1

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
ShirsLazyTrix.HandleQuestProgress()
ShirsLazyTrix.HandleQuestComplete()

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
completable = false
ShirsLazyTrix.HandleQuestProgress()

gossipActive = {}
resetCalls()
ShirsLazyTrix.HandleGossipShow()
gossipActive = { title, 30 }
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 0, "same-NPC omission must not clear a newer incomplete latch")

ShirsLazyTrixDB.automationOnShift = true
active = { { title = "Shift Turn-In", complete = true } }
available = { { title = "Shift Pickup" } }
gossipActive = { "Shift Gossip Turn-In", 30 }
gossipAvailable = { "Shift Gossip Pickup", 30 }
title = "Shift Turn-In"
completable = true
choices = 1
shiftDown = false

resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(countCalls("SelectActiveQuest"), 0, "Shift-required greeting turn-in waits without Shift")
assertEqual(countCalls("SelectAvailableQuest"), 0, "Shift-required greeting pickup waits without Shift")
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(countCalls("SelectGossipActiveQuest"), 0, "Shift-required gossip turn-in waits without Shift")
assertEqual(countCalls("SelectGossipAvailableQuest"), 0, "Shift-required gossip pickup waits without Shift")
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 0, "Shift-required pickup waits without Shift")
resetCalls()
ShirsLazyTrix.HandleQuestProgress()
assertEqual(countCalls("CompleteQuest"), 0, "Shift-required progress waits without Shift")
resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(countCalls("GetQuestReward"), 0, "Shift-required reward waits without Shift")

shiftDown = true
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectActiveQuest")[2], 1, "Shift triggers required greeting turn-in")
assertEqual(countCalls("SelectAvailableQuest"), 0, "turn-in remains ahead of pickup in Shift mode")
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(lastCall("SelectGossipActiveQuest")[2], 1, "Shift triggers required gossip turn-in")
assertEqual(countCalls("SelectGossipAvailableQuest"), 0, "gossip turn-in remains ahead of pickup in Shift mode")
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 1, "Shift triggers required pickup")
resetCalls()
ShirsLazyTrix.HandleQuestProgress()
assertEqual(countCalls("CompleteQuest"), 1, "Shift triggers required quest completion")
resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(lastCall("GetQuestReward")[2], 1, "Shift triggers required reward submission")

active = {}
available = { { title = "Shift Pickup" } }
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectAvailableQuest")[2], 1, "Shift triggers required greeting pickup")
gossipActive = {}
gossipAvailable = { "Shift Gossip Pickup", 30 }
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(lastCall("SelectGossipAvailableQuest")[2], 1, "Shift triggers required gossip pickup")

ShirsLazyTrixDB.pickUp = false
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 0, "pickup master switch still applies in Shift mode")
ShirsLazyTrixDB.pickUp = true

shiftDown = false
ShirsLazyTrixDB.automationOnShift = false

print("controller-defaults-and-migration: PASS")
print("controller-priority: PASS")
print("controller-incomplete-guard: PASS")
print("controller-two-attempt-fallback: PASS")
print("controller-shift-bypass: PASS")
print("controller-shift-required-automation: PASS")
print("controller-rewards: PASS")
