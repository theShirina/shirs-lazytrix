local DEFAULTS = {
  turnInNormal = true,
  pickUpNormal = true,
  turnInRepeatable = false,
  pickUpRepeatable = false,
}

local function npcName()
  local name = UnitName("npc")
  if not name then
    name = UnitName("target")
  end
  return name or ""
end

local function questIsRepeatable(title)
  return ShirsLazyTrix.IsRepeatable(npcName(), title, ShirsLazyTrixDB)
end

local function incompleteKey(npc, title)
  return ShirsLazyTrix.QuestKey(npc, title)
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

  local key, value
  for key, value in pairs(DEFAULTS) do
    if ShirsLazyTrixDB[key] == nil then
      ShirsLazyTrixDB[key] = value
    end
  end

  if type(ShirsLazyTrixDB.repeatableByCharacter) ~= "table" then
    ShirsLazyTrixDB.repeatableByCharacter = {}
  end

  if type(ShirsLazyTrixDB.repeatable) == "table" then
    local repeatables = ShirsLazyTrix.CharacterRepeatables(ShirsLazyTrixDB)
    local questKey, learned
    for questKey, learned in pairs(ShirsLazyTrixDB.repeatable) do
      if learned then
        repeatables[questKey] = true
      end
    end
    ShirsLazyTrixDB.repeatable = nil
  end
end

local function observeAvailable(npc, available)
  local titles = {}
  local i
  for i = 1, table.getn(available) do
    titles[i] = available[i].title
  end
  ShirsLazyTrix.ObserveAvailable(npc, titles, ShirsLazyTrixDB)

  for i = 1, table.getn(available) do
    available[i].repeatable = ShirsLazyTrix.IsRepeatable(npc, available[i].title, ShirsLazyTrixDB)
  end
end

function ShirsLazyTrix.HandleQuestGreeting()
  ShirsLazyTrix.EnsureDatabase()
  local npc = npcName()
  local active = {}
  local available = {}
  local i

  for i = 1, GetNumActiveQuests() do
    local title, complete = GetActiveTitle(i)
    active[i] = {
      title = title,
      complete = applyIncompleteObservation(npc, title, complete),
      repeatable = ShirsLazyTrix.IsRepeatable(npc, title, ShirsLazyTrixDB),
    }
  end

  for i = 1, GetNumAvailableQuests() do
    available[i] = { title = GetAvailableTitle(i) }
  end

  observeAvailable(npc, available)
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
  local npc = npcName()
  local active = collectGossipQuests({ GetGossipActiveQuests() })
  local available = collectGossipQuests({ GetGossipAvailableQuests() })
  local i

  for i = 1, table.getn(active) do
    active[i].complete = applyIncompleteObservation(npc, active[i].title, nil)
    active[i].repeatable = ShirsLazyTrix.IsRepeatable(npc, active[i].title, ShirsLazyTrixDB)
  end

  observeAvailable(npc, available)
  local action, index = ShirsLazyTrix.ChooseGreetingAction(active, available, ShirsLazyTrixDB)
  if action == "active" then
    SelectGossipActiveQuest(index)
  elseif action == "available" then
    SelectGossipAvailableQuest(index)
  end
end

function ShirsLazyTrix.HandleQuestDetail()
  ShirsLazyTrix.EnsureDatabase()
  local title = GetTitleText()
  local repeatable = questIsRepeatable(title)
  if ShirsLazyTrix.IsCategoryEnabled(ShirsLazyTrixDB, "pickup", repeatable) then
    AcceptQuest()
  end
end

function ShirsLazyTrix.HandleQuestProgress()
  ShirsLazyTrix.EnsureDatabase()
  local title = GetTitleText()
  local repeatable = questIsRepeatable(title)
  local completable = IsQuestCompletable()
  ShirsLazyTrix.incompleteSeen = ShirsLazyTrix.incompleteSeen or {}
  local key = incompleteKey(npcName(), title)
  if not completable then
    ShirsLazyTrix.incompleteSeen[key] = true
    return
  end
  ShirsLazyTrix.incompleteSeen[key] = nil
  if ShirsLazyTrix.ShouldCompleteProgress(title, completable, repeatable, ShirsLazyTrixDB) then
    CompleteQuest()
  end
end

function ShirsLazyTrix.HandleQuestComplete()
  ShirsLazyTrix.EnsureDatabase()
  local title = GetTitleText()
  local repeatable = questIsRepeatable(title)
  if not ShirsLazyTrix.IsCategoryEnabled(ShirsLazyTrixDB, "turnin", repeatable) then
    return
  end

  local count = GetNumQuestChoices()
  if count <= 1 then
    ShirsLazyTrix.RememberTurnIn(npcName(), title, ShirsLazyTrixDB)
    GetQuestReward(count)
  end
end
