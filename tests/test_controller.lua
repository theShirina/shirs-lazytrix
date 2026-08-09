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
local player = "Shirina"
local realm = "Icecrown"

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
  if unit == "player" then return player end
  return npc
end
function GetRealmName() return realm end
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
assertEqual(ShirsLazyTrixDB.turnInNormal, true, "normal turn-in default")
assertEqual(ShirsLazyTrixDB.pickUpNormal, true, "normal pickup default")
assertEqual(ShirsLazyTrixDB.turnInRepeatable, false, "repeatable turn-in default")
assertEqual(ShirsLazyTrixDB.pickUpRepeatable, false, "repeatable pickup default")

local legacyQuestKey = ShirsLazyTrix.QuestKey("Legacy NPC", "Legacy Repeatable")
ShirsLazyTrixDB.repeatable = { [legacyQuestKey] = true }
ShirsLazyTrixDB.repeatableByCharacter = nil
ShirsLazyTrix.EnsureDatabase()
assertEqual(ShirsLazyTrixDB.repeatable, nil, "shared repeatable registry is removed after migration")
assertEqual(ShirsLazyTrix.IsRepeatable("Legacy NPC", "Legacy Repeatable", ShirsLazyTrixDB), true, "legacy registry migrates to current character")
player = "ShirinaF2P"
assertEqual(ShirsLazyTrix.IsRepeatable("Legacy NPC", "Legacy Repeatable", ShirsLazyTrixDB), false, "migrated registry does not cross characters")
player = "Shirina"

active = {
  { title = "Incomplete", complete = false },
  { title = "Complete", complete = true },
}
available = { { title = "Available" } }
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(lastCall("SelectActiveQuest")[2], 2, "completed greeting quest is prioritized")
assertEqual(countCalls("SelectAvailableQuest"), 0, "pickup waits for turn-in")

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
assertEqual(lastCall("SelectAvailableQuest")[2], 1, "inspected incomplete quest does not loop or block pickup")
assertEqual(countCalls("SelectActiveQuest"), 0, "inspected incomplete quest stays skipped")

completable = true
resetCalls()
ShirsLazyTrix.HandleQuestProgress()
assertEqual(countCalls("CompleteQuest"), 1, "completable normal quest continues")

choices = 2
resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(countCalls("GetQuestReward"), 0, "multiple rewards wait for player")

choices = 1
resetCalls()
ShirsLazyTrix.HandleQuestComplete()
assertEqual(lastCall("GetQuestReward")[2], 1, "single reward is selected")

-- Exact Vanilla gossip tuples are title/level pairs.
gossipActive = { "Active Gossip Quest", 30 }
gossipAvailable = { "Available Gossip Quest", 30 }
resetCalls()
ShirsLazyTrix.HandleGossipShow()
assertEqual(lastCall("SelectGossipActiveQuest")[2], 1, "gossip active quest is inspected before pickup")
assertEqual(countCalls("SelectGossipAvailableQuest"), 0, "gossip pickup waits for active quest")

-- The just-completed title reappears from the same NPC and becomes repeatable.
active = {}
available = { { title = "Legacy Active" } }
resetCalls()
ShirsLazyTrix.HandleQuestGreeting()
assertEqual(ShirsLazyTrix.IsRepeatable(npc, "Legacy Active", ShirsLazyTrixDB), true, "repeatable learned after confirmed reward")
assertEqual(countCalls("SelectAvailableQuest"), 0, "disabled repeatable pickup stays closed")

-- Normal detail accepts; learned repeatable detail obeys its separate switch.
title = "Normal Offer"
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 1, "normal pickup")

title = "Legacy Active"
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 0, "disabled repeatable pickup")

ShirsLazyTrixDB.pickUpRepeatable = true
resetCalls()
ShirsLazyTrix.HandleQuestDetail()
assertEqual(countCalls("AcceptQuest"), 1, "enabled repeatable pickup")

print("controller-defaults: PASS")
print("controller-priority: PASS")
print("controller-incomplete-guard: PASS")
print("controller-rewards: PASS")
print("controller-repeatable: PASS")
