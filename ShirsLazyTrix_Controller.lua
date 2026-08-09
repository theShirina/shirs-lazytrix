local DEFAULTS = {
  turnIn = true,
  pickUp = true,
  automationOnShift = false,
  autoSellGray = false,
  minimapAngle = 220,
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

local function automationAllowed(held)
  if ShirsLazyTrixDB.automationOnShift then return held and true or false end
  return not held
end

local function turnInAllowed(held)
  return ShirsLazyTrixDB.turnIn and automationAllowed(held)
end

local function pickUpAllowed(held)
  return ShirsLazyTrixDB.pickUp and automationAllowed(held)
end

local function dialogSettings(held)
  return {
    turnIn = turnInAllowed(held),
    pickUp = pickUpAllowed(held),
  }
end

local function incompleteKey(npc, title)
  return (npc or "") .. "\031" .. (title or "")
end

local function incompleteTitle(key)
  local _, separator = string.find(key, "\031", 1, true)
  if not separator then return key end
  return string.sub(key, separator + 1)
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
  if ShirsLazyTrixDB.automationOnShift == nil and ShirsLazyTrixDB.turnInOnShift == true then
    ShirsLazyTrixDB.automationOnShift = true
  end

  local key, value
  for key, value in pairs(DEFAULTS) do
    if ShirsLazyTrixDB[key] == nil then
      ShirsLazyTrixDB[key] = value
    end
  end

  if type(ShirsLazyTrixDB.automationOnShift) ~= "boolean" then
    ShirsLazyTrixDB.automationOnShift = DEFAULTS.automationOnShift
  end
  if type(ShirsLazyTrixDB.autoSellGray) ~= "boolean" then
    ShirsLazyTrixDB.autoSellGray = DEFAULTS.autoSellGray
  end
  if type(ShirsLazyTrixDB.minimapAngle) ~= "number" or
     ShirsLazyTrixDB.minimapAngle < 0 or ShirsLazyTrixDB.minimapAngle >= 360 then
    ShirsLazyTrixDB.minimapAngle = DEFAULTS.minimapAngle
  end

  ShirsLazyTrixDB.turnInNormal = nil
  ShirsLazyTrixDB.pickUpNormal = nil
  ShirsLazyTrixDB.turnInOnShift = nil
  ShirsLazyTrixDB.turnInRepeatable = nil
  ShirsLazyTrixDB.pickUpRepeatable = nil
  ShirsLazyTrixDB.repeatable = nil
  ShirsLazyTrixDB.repeatableByCharacter = nil
end

function ShirsLazyTrix.HandleQuestGreeting()
  ShirsLazyTrix.EnsureDatabase()
  local held = shiftHeld()
  if not automationAllowed(held) then return end

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

  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, dialogSettings(held))
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
  local held = shiftHeld()
  if not automationAllowed(held) then return end

  local npc = npcName()
  local active = collectGossipQuests({ GetGossipActiveQuests() })
  local available = collectGossipQuests({ GetGossipAvailableQuests() })
  local i

  for i = 1, table.getn(active) do
    active[i].complete = applyIncompleteObservation(npc, active[i].title, nil)
  end

  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, dialogSettings(held))
  if action == "active" then
    SelectGossipActiveQuest(index)
  elseif action == "available" then
    SelectGossipAvailableQuest(index)
  end
end

function ShirsLazyTrix.HandleQuestDetail()
  ShirsLazyTrix.EnsureDatabase()
  if pickUpAllowed(shiftHeld()) then
    AcceptQuest()
  end
end

function ShirsLazyTrix.HandleQuestProgress()
  ShirsLazyTrix.EnsureDatabase()
  if not turnInAllowed(shiftHeld()) then return end

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
  if not turnInAllowed(shiftHeld()) then
    return
  end

  local count = GetNumQuestChoices()
  if count <= 1 then
    GetQuestReward(count)
  end
end

function ShirsLazyTrix.HandleQuestLogUpdate()
  if type(ShirsLazyTrix.incompleteSeen) ~= "table" then return end

  local completed = {}
  local i
  for i = 1, GetNumQuestLogEntries() do
    local title, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
    if title and not isHeader and isComplete then
      completed[title] = true
    end
  end

  local remove = {}
  local key
  for key in pairs(ShirsLazyTrix.incompleteSeen) do
    if completed[incompleteTitle(key)] then
      table.insert(remove, key)
    end
  end
  for i = 1, table.getn(remove) do
    ShirsLazyTrix.incompleteSeen[remove[i]] = nil
  end
end
