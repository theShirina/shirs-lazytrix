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
  turnInNormal = true,
  pickUpNormal = true,
  turnInRepeatable = false,
  pickUpRepeatable = false,
  repeatable = {},
}

local action, index = ShirsLazyTrix.ChooseGreetingAction(
  {
    { title = "Still Working", complete = false, repeatable = false },
    { title = "Ready to Turn In", complete = true, repeatable = false },
  },
  {
    { title = "New Quest", repeatable = false },
  },
  db
)

assertEqual(action, "active", "completed turn-in must beat pickup")
assertEqual(index, 2, "completed turn-in index")

local incompleteAction = ShirsLazyTrix.ChooseGreetingAction(
  {
    { title = "Still Working", complete = false, repeatable = false },
  },
  {
    { title = "New Quest", repeatable = false },
  },
  db
)
assertEqual(incompleteAction, "available", "known incomplete active quest must not block pickup")

local unknownAction, unknownIndex = ShirsLazyTrix.ChooseGreetingAction(
  {
    { title = "Legacy Active Quest", complete = nil, repeatable = false },
  },
  {
    { title = "New Quest", repeatable = false },
  },
  db
)
assertEqual(unknownAction, "active", "unknown legacy completion state must be inspected before pickup")
assertEqual(unknownIndex, 1, "unknown legacy active index")

assertEqual(ShirsLazyTrix.ShouldCompleteProgress("Normal Quest", false, false, db), false, "incomplete quest safety gate")
assertEqual(ShirsLazyTrix.ShouldCompleteProgress("Normal Quest", true, false, db), true, "normal quest completion")
assertEqual(ShirsLazyTrix.ShouldCompleteProgress("Repeatable Quest", true, true, db), false, "disabled repeatable turn-in")

ShirsLazyTrix.characterKeyOverride = "Icecrown\031Shirina"
ShirsLazyTrix.RememberTurnIn("Argent Officer", "A Donation of Wool", db)
assertEqual(ShirsLazyTrix.ObserveAvailable("Other Officer", { "A Donation of Wool" }, db), false, "different NPC must not learn repeatable")
assertEqual(ShirsLazyTrix.ObserveAvailable("Argent Officer", { "Another Quest" }, db), false, "different title must not learn repeatable")
assertEqual(ShirsLazyTrix.ObserveAvailable("Argent Officer", { "A Donation of Wool" }, db), true, "same NPC and title learns repeatable")
assertEqual(ShirsLazyTrix.IsRepeatable("Argent Officer", "A Donation of Wool", db), true, "learned repeatable lookup")

ShirsLazyTrix.characterKeyOverride = "Icecrown\031ShirinaF2P"
assertEqual(ShirsLazyTrix.IsRepeatable("Argent Officer", "A Donation of Wool", db), false, "learned repeatable must not cross characters")
ShirsLazyTrix.characterKeyOverride = "Icecrown\031Shirina"
assertEqual(ShirsLazyTrix.IsRepeatable("Argent Officer", "A Donation of Wool", db), true, "original character keeps learned repeatable")

print("turn-in-priority: PASS")
print("incomplete-quest-guard: PASS")
print("repeatable-learning: PASS")
print("per-character-repeatable-learning: PASS")
