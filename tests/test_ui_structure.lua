-- Structural UI contract for Shir's LazyTrix

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

assertContains('frame:SetWidth(340)', "minimal settings width")
assertContains('frame:SetHeight(350)', "minimal settings height")
assertContains('UI-Tooltip-Background', "addon-family dark panel background")
assertContains('UI-Tooltip-Border', "addon-family thin panel border")
assertContains('frame:SetBackdropColor(0.025, 0.035, 0.055, 0.98)', "dark navy panel color")
assertContains('frame:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)', "blue panel border")
assertContains('title:SetTextColor(0.45, 0.82, 1)', "blue addon title")
assertContains('"AUTOMATION"', "minimal section heading")
assertContains('section:SetTextColor(1, 0.82, 0)', "gold section heading")
assertContains('button:SetWidth(32)', "standard minimap button width")
assertContains('button:SetHeight(32)', "standard minimap button height")
assertContains('icon:SetWidth(20)', "filled minimap icon width")
assertContains('icon:SetHeight(20)', "filled minimap icon height")
assertContains('button:CreateTexture(nil, "ARTWORK")', "icon artwork layer")
assertContains('Interface\\\\AddOns\\\\ShirsLazyTrix\\\\LazyTrixIcon', "custom LazyTrix icon")
assertContains('MiniMap-TrackingBorder', "minimap tracking border")
assertContains('border:SetWidth(52)', "standard border width")
assertContains('button:RegisterForDrag("LeftButton")', "movable minimap registration")
assertContains('ShirsLazyTrixDB.minimapAngle', "saved minimap angle")
assertContains('math.atan2', "cursor angle calculation")
assertContains('"Drag: Move this button"', "minimap drag tooltip")
assertContains('"Turn in completed quests", "turnIn"', "turn-in checkbox")
assertContains('"Pick up quests", "pickUp"', "pickup checkbox")
assertContains('"Only automate while Shift is held", "automationOnShift"', "Shift-required automation checkbox")
assertContains("When enabled, Shift triggers both pickup and turn-in.", "Shift behavior note")
assertContains('"MERCHANT"', "merchant section heading")
assertContains('"Automatically sell gray items at vendors", "autoSellGray"', "gray-only merchant checkbox")
assertContains('"Automatically repair all gear at repair vendors", "autoRepairAll"', "automatic repair checkbox")
assertContains("Sells gray-quality items only. Vendor options run independently.", "merchant boundary note")
assertContains('table.insert(UISpecialFrames, "ShirsLazyTrixSettingsFrame")', "Escape closes settings")
assertAbsent("repeatable", "repeatable controls must be removed")

if count('createCheckbox(') ~= 6 then
  error("UI must define exactly five checkbox calls plus the helper", 2)
end

print("ui-minimal-family-style: PASS")
print("ui-movable-filled-minimap: PASS")
print("ui-five-setting-structure: PASS")
