local DEFAULTS = {
  turnIn = true,
  pickUp = true,
}

local function npcName()
  local name = UnitName("npc")
  if not name then
    name = UnitName("target")
  end
  return name or ""
end

local function shiftHeld()
  return type(IsShiftKeyDown) == "function" and IsShiftKeyDown() and true or false
end

local function incompleteKey(npc, title)
  return (npc or "") .. "\031" .. (title or "")
end

local function applyIncompleteObservation(npc, title, complete)
  ShirsLazyTrix.incompleteSeen = ShirsLazyTrix.incompleteSeen or {}
  local key = incompleteKey(npc, title)
  if complete then
    ShirsLazyTrix.incompleteSeen[key] = nil
    return true
  end
  if complete == nil and ShirsLazyTrix.incompleteSeen[key] then
    return false
  end
  return complete
end

function ShirsLazyTrix.EnsureDatabase()
  if type(ShirsLazyTrixDB) ~= "table" then
    ShirsLazyTrixDB = {}
  end

  if ShirsLazyTrixDB.turnIn == nil and ShirsLazyTrixDB.turnInNormal ~= nil then
    ShirsLazyTrixDB.turnIn = ShirsLazyTrixDB.turnInNormal and true or false
  end
  if ShirsLazyTrixDB.pickUp == nil and ShirsLazyTrixDB.pickUpNormal ~= nil then
    ShirsLazyTrixDB.pickUp = ShirsLazyTrixDB.pickUpNormal and true or false
  end

  local key, value
  for key, value in pairs(DEFAULTS) do
    if ShirsLazyTrixDB[key] == nil then
      ShirsLazyTrixDB[key] = value
    end
  end

  ShirsLazyTrixDB.turnInNormal = nil
  ShirsLazyTrixDB.pickUpNormal = nil
  ShirsLazyTrixDB.turnInRepeatable = nil
  ShirsLazyTrixDB.pickUpRepeatable = nil
  ShirsLazyTrixDB.repeatable = nil
  ShirsLazyTrixDB.repeatableByCharacter = nil
end

function ShirsLazyTrix.HandleQuestGreeting()
  ShirsLazyTrix.EnsureDatabase()
  if shiftHeld() then return end

  local npc = npcName()
  local active = {}
  local available = {}
  local i

  for i = 1, GetNumActiveQuests() do
    local title, complete = GetActiveTitle(i)
    active[i] = {
      title = title,
      complete = applyIncompleteObservation(npc, title, complete),
    }
  end

  for i = 1, GetNumAvailableQuests() do
    available[i] = { title = GetAvailableTitle(i) }
  end

  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, ShirsLazyTrixDB)
  if action == "active" then
    SelectActiveQuest(index)
  elseif action == "available" then
    SelectAvailableQuest(index)
  end
end

local function collectGossipQuests(values)
  local quests = {}
  local questIndex = 1
  local i
  for i = 1, table.getn(values), 2 do
    if values[i] then
      quests[questIndex] = { title = values[i] }
      questIndex = questIndex + 1
    end
  end
  return quests
end

function ShirsLazyTrix.HandleGossipShow()
  ShirsLazyTrix.EnsureDatabase()
  if shiftHeld() then return end

  local npc = npcName()
  local active = collectGossipQuests({ GetGossipActiveQuests() })
  local available = collectGossipQuests({ GetGossipAvailableQuests() })
  local i

  for i = 1, table.getn(active) do
    active[i].complete = applyIncompleteObservation(npc, active[i].title, nil)
  end

  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, ShirsLazyTrixDB)
  if action == "active" then
    SelectGossipActiveQuest(index)
  elseif action == "available" then
    SelectGossipAvailableQuest(index)
  end
end

function ShirsLazyTrix.HandleQuestDetail()
  ShirsLazyTrix.EnsureDatabase()
  if shiftHeld() then return end
  if ShirsLazyTrixDB.pickUp then
    AcceptQuest()
  end
end

function ShirsLazyTrix.HandleQuestProgress()
  ShirsLazyTrix.EnsureDatabase()
  if shiftHeld() then return end

  local title = GetTitleText()
  local completable = IsQuestCompletable()
  ShirsLazyTrix.incompleteSeen = ShirsLazyTrix.incompleteSeen or {}
  local key = incompleteKey(npcName(), title)
  if not completable then
    ShirsLazyTrix.incompleteSeen[key] = true
    return
  end
  ShirsLazyTrix.incompleteSeen[key] = nil
  if ShirsLazyTrix.ShouldCompleteProgress(completable, ShirsLazyTrixDB) then
    CompleteQuest()
  end
end

function ShirsLazyTrix.HandleQuestComplete()
  ShirsLazyTrix.EnsureDatabase()
  if shiftHeld() or not ShirsLazyTrixDB.turnIn then
    return
  end

  local count = GetNumQuestChoices()
  if count <= 1 then
    GetQuestReward(count)
  end
end

function ShirsLazyTrix.HandleQuestFinished()
  ShirsLazyTrix.incompleteSeen = nil
end
