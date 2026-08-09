-- Shir's LazyTrix open-world resurrection tests for Lua 5.0.3

local root = arg and arg[1] or "."

ShirsLazyTrix = {}
ShirsLazyTrixDB = { autoAcceptOpenWorldRes = false }

local accepted = 0
local hidden = {}
local instanceValue = nil
local instanceType = nil
local exposeInstanceApi = true
local exposeAcceptApi = true

function ShirsLazyTrix.EnsureDatabase() end

local function installApis()
  if exposeInstanceApi then
    IsInInstance = function() return instanceValue, instanceType end
  else
    IsInInstance = nil
  end

  if exposeAcceptApi then
    AcceptResurrect = function() accepted = accepted + 1 end
  else
    AcceptResurrect = nil
  end

  StaticPopup_Hide = function(name)
    table.insert(hidden, name)
  end
end

local function reset(enabled, inside, kind)
  ShirsLazyTrixDB.autoAcceptOpenWorldRes = enabled
  accepted = 0
  hidden = {}
  instanceValue = inside
  instanceType = kind
  exposeInstanceApi = true
  exposeAcceptApi = true
  installApis()
end

assert(loadfile(root .. "/ShirsLazyTrix_World.lua"))()

reset(false, nil, nil)
assert(ShirsLazyTrix.TryAutoAcceptResurrection() == false, "disabled resurrection automation must return false")
assert(accepted == 0 and table.getn(hidden) == 0, "disabled resurrection automation changed the pending request")

reset(true, nil, nil)
exposeInstanceApi = false
installApis()
assert(ShirsLazyTrix.TryAutoAcceptResurrection() == false, "missing location API must fail closed")
assert(accepted == 0, "missing location API accepted a resurrection")

reset(true, nil, nil)
exposeAcceptApi = false
installApis()
assert(ShirsLazyTrix.TryAutoAcceptResurrection() == false, "missing acceptance API must fail closed")
assert(table.getn(hidden) == 0, "missing acceptance API hid the pending request")

local blocked = {
  { true, "party" },
  { 1, nil },
  { true, "raid" },
  { true, "pvp" },
  { true, "arena" },
  { false, "party" },
  { 0, "raid" },
  { "yes", nil },
}
local i
for i = 1, table.getn(blocked) do
  reset(true, blocked[i][1], blocked[i][2])
  assert(ShirsLazyTrix.TryAutoAcceptResurrection() == false, "instance or ambiguous location must fail closed")
  assert(accepted == 0 and table.getn(hidden) == 0, "instance or ambiguous location changed the pending request")
end

local outside = {
  { nil, nil },
  { false, nil },
  { false, "none" },
  { 0, nil },
  { 0, "none" },
}
for i = 1, table.getn(outside) do
  reset(true, outside[i][1], outside[i][2])
  assert(ShirsLazyTrix.TryAutoAcceptResurrection() == true, "explicit open-world state did not accept resurrection")
  assert(accepted == 1, "open-world resurrection must submit exactly once")
  assert(table.getn(hidden) == 3, "accepted resurrection must hide all exact-client popup variants")
  assert(hidden[1] == "RESURRECT_NO_TIMER" and hidden[2] == "RESURRECT_NO_SICKNESS" and hidden[3] == "RESURRECT",
    "resurrection popup cleanup order changed")
end

assert(type(RepopMe) == "nil", "world module must not define or call corpse release")
print("OPEN_WORLD_RESURRECTION_TEST=PASS")
