-- Structural UI contract for Shir's LazyTrix 0.0.1

local root = arg and arg[1] or "."
local path = root .. "/ShirsLazyTrix_UI.lua"
local file = io.open(path, "rb")
if not file then
  error("missing ShirsLazyTrix_UI.lua", 2)
end
local source = file:read("*a")
file:close()

local function assertContains(text, message)
  if not string.find(source, text, 1, true) then
    error(message .. ": missing " .. text, 2)
  end
end

local function count(text)
  local total = 0
  local start = 1
  while true do
    local found = string.find(source, text, start, true)
    if not found then return total end
    total = total + 1
    start = found + string.len(text)
  end
end

assertContains('frame:SetWidth(360)', "minimal settings width")
assertContains('frame:SetHeight(290)', "minimal settings height")
assertContains('button:SetWidth(24)', "minimap button width")
assertContains('button:SetHeight(24)', "minimap button height")
assertContains('"Normal quests"', "normal section")
assertContains('"Repeatable quests"', "repeatable section")
assertContains('"Turn in completed quests", "turnInNormal"', "normal turn-in checkbox")
assertContains('"Pick up quests", "pickUpNormal"', "normal pickup checkbox")
assertContains('"Turn in completed quests", "turnInRepeatable"', "repeatable turn-in checkbox")
assertContains('"Pick up quests", "pickUpRepeatable"', "repeatable pickup checkbox")
assertContains("Repeatable quests are learned separately per character after their first completed cycle.", "repeatable learning note")

if count('createCheckbox(') ~= 5 then
  error("UI must define exactly four checkbox calls plus the helper", 2)
end

print("ui-minimal-structure: PASS")
