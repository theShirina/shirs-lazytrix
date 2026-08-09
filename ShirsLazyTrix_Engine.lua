ShirsLazyTrix = ShirsLazyTrix or {}

local function actionEnabled(db, action)
  if action == "turnin" then
    return db.turnIn and true or false
  end
  return db.pickUp and true or false
end

function ShirsLazyTrix.ShouldCompleteProgress(completable, db)
  if not completable then
    return false
  end
  return actionEnabled(db, "turnin")
end

function ShirsLazyTrix.ChooseGreetingAction(active, available, db)
  local i
  for i = 1, table.getn(active) do
    local quest = active[i]
    if quest.complete and actionEnabled(db, "turnin") then
      return "active", i
    end
  end

  for i = 1, table.getn(active) do
    local quest = active[i]
    if quest.complete == nil and actionEnabled(db, "turnin") then
      return "active", i
    end
  end

  if actionEnabled(db, "pickup") then
    for i = 1, table.getn(available) do
      return "available", i
    end
  end

  return nil, nil
end
