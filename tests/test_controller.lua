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

dofile(root .. "/ShirsLazyTrix_Controller.lua")

ShirsLazyTrixDB = nil
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.turnIn, true, "turn-in default")
assertEqual(ShirsLazyTrixDB.pickUp, true, "pickup default")

ShirsLazyTrixDB = {
  turnInNormal = false,
  pickUpNormal = true,
  turnInRepeatable = true,
  pickUpRepeatable = true,
  repeatable = { old = true },
  repeatableByCharacter = { old = true },
}
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.turnIn, false, "old normal turn-in setting migrates")
assertEqual(ShirsLazyTrixDB.pickUp, true, "old normal pickup setting migrates")
assertEqual(ShirsLazyTrixDB.turnInNormal, nil, "old normal turn-in key removed")
assertEqual(ShirsLazyTrixDB.pickUpNormal, nil, "old normal pickup key removed")
assertEqual(ShirsLazyTrixDB.turnInRepeatable, nil, "old repeatable turn-in key removed")
assertEqual(ShirsLazyTrixDB.pickUpRepeatable, nil, "old repeatable pickup key removed")
assertEqual(ShirsLazyTrixDB.repeatable, nil, "old shared learner removed")
assertEqual(ShirsLazyTrixDB.repeatableByCharacter, nil, "old character learner removed")
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

ShirsLazyTrix.HandleQuestFinished()
gossipActive = { "Legacy Active", 30 }
gossipAvailable = {}
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(lastCall("SelectGossipActiveQuest")[2], 1, "new NPC interaction rechecks formerly incomplete quest")

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

print("controller-defaults-and-migration: PASS")
print("controller-priority: PASS")
print("controller-incomplete-guard: PASS")
print("controller-shift-bypass: PASS")
print("controller-rewards: PASS")
