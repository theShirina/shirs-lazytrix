ShirsLazyTrix = ShirsLazyTrix or {}

local function categoryEnabled(db, action, repeatable)
  if action == "turnin" then
    if repeatable then
      return db.turnInRepeatable and true or false
    end
    return db.turnInNormal and true or false
  end

  if repeatable then
    return db.pickUpRepeatable and true or false
  end
  return db.pickUpNormal and true or false
end

function ShirsLazyTrix.QuestKey(npc, title)
  return (npc or "") .. "\031" .. (title or "")
end

function ShirsLazyTrix.IsRepeatable(npc, title, db)
  if not db or not db.repeatable then
    return false
  end
  return db.repeatable[ShirsLazyTrix.QuestKey(npc, title)] and true or false
end

function ShirsLazyTrix.RememberTurnIn(npc, title, db)
  ShirsLazyTrix.recentTurnIn = {
    npc = npc or "",
    title = title or "",
  }
end

function ShirsLazyTrix.ObserveAvailable(npc, titles, db)
  local recent = ShirsLazyTrix.recentTurnIn
  if not recent or recent.npc ~= (npc or "") then
    return false
  end

  local i
  for i = 1, table.getn(titles) do
    if titles[i] == recent.title then
      db.repeatable = db.repeatable or {}
      db.repeatable[ShirsLazyTrix.QuestKey(npc, recent.title)] = true
      ShirsLazyTrix.recentTurnIn = nil
      return true
    end
  end

  return false
end

function ShirsLazyTrix.ShouldCompleteProgress(title, completable, repeatable, db)
  if not completable then
    return false
  end
  return categoryEnabled(db, "turnin", repeatable)
end

function ShirsLazyTrix.IsCategoryEnabled(db, action, repeatable)
  return categoryEnabled(db, action, repeatable)
end

function ShirsLazyTrix.ChooseGreetingAction(active, available, db)
  local i
  for i = 1, table.getn(active) do
    local quest = active[i]
    if quest.complete and categoryEnabled(db, "turnin", quest.repeatable) then
      return "active", i
    end
  end

  for i = 1, table.getn(active) do
    local quest = active[i]
    if quest.complete == nil and categoryEnabled(db, "turnin", quest.repeatable) then
      return "active", i
    end
  end

  for i = 1, table.getn(available) do
    local quest = available[i]
    if categoryEnabled(db, "pickup", quest.repeatable) then
      return "available", i
    end
  end

  return nil, nil
end
