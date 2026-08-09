local DEFAULTS = {
  turnIn = true,
  pickUp = true,
  automationOnShift = false,
  autoSellGray = false,
  autoRepairAll = false,
  autoAcceptOpenWorldRes = false,
  autoRemoveImmolationOnStealth = false,
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

local function incompleteNpc(key)
  local start = string.find(key, "\031", 1, true)
  if not start then return "" end
  return string.sub(key, 1, start - 1)
end

local function confirmMissingTurnIns(npc, active)
  if type(ShirsLazyTrix.pendingTurnInSuccess) ~= "table" then return end

  local present = {}
  local i
  for i = 1, table.getn(active) do
    present[active[i].title] = true
  end

  local remove = {}
  local key
  for key in pairs(ShirsLazyTrix.pendingTurnInSuccess) do
    if incompleteNpc(key) == npc and not present[incompleteTitle(key)] then
      table.insert(remove, key)
    end
  end

  for i = 1, table.getn(remove) do
    key = remove[i]
    ShirsLazyTrix.pendingTurnInSuccess[key] = nil
    if type(ShirsLazyTrix.turnInAttempts) == "table" then
      ShirsLazyTrix.turnInAttempts[key] = nil
    end
  end
end

local function turnInAttemptAvailable(npc, title)
  if type(ShirsLazyTrix.turnInAttempts) ~= "table" then return true end
  return (ShirsLazyTrix.turnInAttempts[incompleteKey(npc, title)] or 0) < 2
end

local function recordTurnInAttempt(npc, title)
  ShirsLazyTrix.turnInAttempts = ShirsLazyTrix.turnInAttempts or {}
  local key = incompleteKey(npc, title)
  ShirsLazyTrix.turnInAttempts[key] = (ShirsLazyTrix.turnInAttempts[key] or 0) + 1
end

local function applyTurnInAttemptLimit(npc, title, complete)
  if not turnInAttemptAvailable(npc, title) then return false end
  return complete
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
  if type(ShirsLazyTrixDB.autoRepairAll) ~= "boolean" then
    ShirsLazyTrixDB.autoRepairAll = DEFAULTS.autoRepairAll
  end
  if type(ShirsLazyTrixDB.autoAcceptOpenWorldRes) ~= "boolean" then
    ShirsLazyTrixDB.autoAcceptOpenWorldRes = DEFAULTS.autoAcceptOpenWorldRes
  end
  if type(ShirsLazyTrixDB.autoRemoveImmolationOnStealth) ~= "boolean" then
    ShirsLazyTrixDB.autoRemoveImmolationOnStealth = DEFAULTS.autoRemoveImmolationOnStealth
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
      complete = complete,
    }
  end

  confirmMissingTurnIns(npc, active)
  for i = 1, table.getn(active) do
    active[i].complete = applyTurnInAttemptLimit(
      npc,
      active[i].title,
      applyIncompleteObservation(npc, active[i].title, active[i].complete)
    )
  end

  for i = 1, GetNumAvailableQuests() do
    available[i] = { title = GetAvailableTitle(i) }
  end

  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, dialogSettings(held))
  if action == "active" then
    recordTurnInAttempt(npc, active[index].title)
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

  confirmMissingTurnIns(npc, active)
  for i = 1, table.getn(active) do
    active[i].complete = applyTurnInAttemptLimit(
      npc,
      active[i].title,
      applyIncompleteObservation(npc, active[i].title, nil)
    )
  end

  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, dialogSettings(held))
  if action == "active" then
    recordTurnInAttempt(npc, active[index].title)
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
  ShirsLazyTrix.currentTurnInKey = nil
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
    ShirsLazyTrix.currentTurnInKey = key
    CompleteQuest()
  end
end

function ShirsLazyTrix.HandleQuestComplete()
  ShirsLazyTrix.EnsureDatabase()
  if not turnInAllowed(shiftHeld()) then
    ShirsLazyTrix.currentTurnInKey = nil
    return
  end

  local count = GetNumQuestChoices()
  if count <= 1 then
    local key = ShirsLazyTrix.currentTurnInKey or incompleteKey(npcName(), GetTitleText())
    ShirsLazyTrix.pendingTurnInSuccess = ShirsLazyTrix.pendingTurnInSuccess or {}
    ShirsLazyTrix.pendingTurnInSuccess[key] = true
    GetQuestReward(count)
  end
  ShirsLazyTrix.currentTurnInKey = nil
end

function ShirsLazyTrix.HandleQuestLogUpdate()
  -- Quest-log titles do not identify an NPC. Retry state is cleared only from
  -- the same NPC's next active-quest list in HandleQuestGreeting/HandleGossipShow.
end
