-- Shir's LazyTrix engine tests for Lua 5.0.3

local root = arg and arg[1] or "."
dofile(root .. "/ShirsLazyTrix_Engine.lua")

local function fail(message)
  error(message, 2)
end

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    fail((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local db = {
  turnIn = true,
  pickUp = true,
}

local action, index = ShirsLazyTrix.ChooseGreetingAction(
  {
    { title = "Still Working", complete = false },
    { title = "Ready to Turn In", complete = true },
  },
  {
    { title = "New Quest" },
  },
  db
)

assertEqual(action, "active", "completed turn-in must beat pickup")
assertEqual(index, 2, "completed turn-in index")

local incompleteAction = ShirsLazyTrix.ChooseGreetingAction(
  {
    { title = "Still Working", complete = false },
  },
  {
    { title = "New Quest" },
  },
  db
)
assertEqual(incompleteAction, "available", "known incomplete active quest must not block pickup")

local unknownAction, unknownIndex = ShirsLazyTrix.ChooseGreetingAction(
  {
    { title = "Legacy Active Quest", complete = nil },
  },
  {
    { title = "New Quest" },
  },
  db
)
assertEqual(unknownAction, "active", "unknown legacy completion state must be inspected before pickup")
assertEqual(unknownIndex, 1, "unknown legacy active index")

assertEqual(ShirsLazyTrix.ShouldCompleteProgress(false, db), false, "incomplete quest safety gate")
assertEqual(ShirsLazyTrix.ShouldCompleteProgress(true, db), true, "completed quest can continue")

db.turnIn = false
assertEqual(ShirsLazyTrix.ShouldCompleteProgress(true, db), false, "disabled turn-in")
db.turnIn = true

db.pickUp = false
local disabledAction = ShirsLazyTrix.ChooseGreetingAction({}, { { title = "New Quest" } }, db)
assertEqual(disabledAction, nil, "disabled pickup")

print("turn-in-priority: PASS")
print("incomplete-quest-guard: PASS")
print("two-setting-engine: PASS")
