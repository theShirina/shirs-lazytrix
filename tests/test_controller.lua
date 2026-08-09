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
assertEqual(ShirsLazyTrixDB.minimapAngle, 220, "minimap angle default")

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
  minimapAngle = "invalid",
}
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.turnIn, false, "old normal turn-in setting migrates")
assertEqual(ShirsLazyTrixDB.pickUp, true, "old normal pickup setting migrates")
assertEqual(ShirsLazyTrixDB.automationOnShift, true, "temporary turn-in-only Shift setting migrates")
assertEqual(ShirsLazyTrixDB.autoSellGray, false, "invalid automatic gray sale setting repairs")
assertEqual(ShirsLazyTrixDB.autoRepairAll, false, "invalid automatic repair setting repairs")
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
