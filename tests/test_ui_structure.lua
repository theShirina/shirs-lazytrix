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

local function assertAbsent(text, message)
  if string.find(string.lower(source), string.lower(text), 1, true) then
    error(message .. ": found " .. text, 2)
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
assertContains('button:SetWidth(24)', "minimap button width")
assertContains('button:SetHeight(24)', "minimap button height")
assertContains('"Turn in completed quests", "turnIn"', "turn-in checkbox")
assertContains('"Pick up quests", "pickUp"', "pickup checkbox")
assertContains("Hold Shift to handle a quest manually.", "Shift bypass note")
assertAbsent("repeatable", "repeatable controls must be removed")

if count('createCheckbox(') ~= 3 then
  error("UI must define exactly two checkbox calls plus the helper", 2)
end

print("ui-two-setting-structure: PASS")
print("ui-shift-note: PASS")
