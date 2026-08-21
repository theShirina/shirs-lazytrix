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

assertContains('frame:SetWidth(620)', "two-column settings width")
assertContains('frame:SetHeight(510)', "compact settings height")
assertContains('UI-Tooltip-Background', "addon-family dark panel background")
assertContains('UI-Tooltip-Border', "addon-family thin panel border")
assertContains('frame:SetBackdropColor(0.025, 0.035, 0.055, 0.98)', "dark navy panel color")
assertContains('frame:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)', "blue panel border")
assertContains('title:SetTextColor(0.45, 0.82, 1)', "blue addon title")
assertContains('"QUESTING"', "questing section heading")
assertContains('"WORLD"', "world section heading")
assertContains('"TRAINERS"', "trainer section heading")
assertContains('verticalDivider:SetHeight(410)', "two-column divider height")
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
assertContains("Shift can trigger both pickup and turn-in.", "Shift behavior note")
assertContains('"Accept open-world resurrection requests", "autoAcceptOpenWorldRes"', "open-world resurrection checkbox")
assertContains('"Remove immolation on stealth or invisibility", "autoRemoveImmolationOnStealth"', "stealth immolation cleanup checkbox")
assertContains('"Expand trainer windows", "expandTrainers"', "expanded trainer checkbox")
assertContains('"Enable Train All", "trainAll"', "Train All checkbox")
assertContains('"Automatically open trainer services", "autoOpenTrainers"', "automatic trainer gossip checkbox")
assertContains('"Show movable cooldown panel", "showCooldownPanel"', "profession cooldown panel checkbox")
assertContains('"Hide in combat and instances", "hideCooldownPanelInCombat"', "cooldown combat-and-instance-hide checkbox")
assertContains('"OTHER-CHARACTER READY REMINDERS"', "other-character reminder heading")
assertContains('"Mooncloth", "notifyOtherMooncloth"', "Mooncloth reminder checkbox")
assertContains('"Arcanite", "notifyOtherArcanite"', "Arcanite reminder checkbox")
assertContains('"Salt", "notifyOtherSalt"', "Salt Shaker reminder checkbox")
assertContains('"TOOLTIPS"', "tooltip section heading")
assertContains('"Show item IDs in tooltips", "showItemIDs"', "item-ID tooltip checkbox")
assertContains('"Collect addon minimap buttons"', "minimap collector checkbox")
assertContains('"ShirsLazyTrixLootRowsSlider"', "stock loot row slider")
assertContains('"ShirsLazyTrixMinimapButtonSizeSlider"', "collected minimap button size slider")
assertContains('"PROFESSION COOLDOWNS"', "profession cooldown section heading")
assertContains('CreateFrame("Frame", "ShirsLazyTrixCooldownPanel", UIParent)', "movable cooldown panel")
assertContains('CreateFrame("Button", "ShirsLazyTrixCooldownMooncloth"', "clickable Mooncloth row")
assertContains('CreateFrame("Button", "ShirsLazyTrixCooldownArcanite"', "clickable Arcanite row")
assertContains('CreateFrame("Button", "ShirsLazyTrixCooldownSalt"', "clickable Salt Shaker row")
assertContains('CreateFrame("Button", "ShirsLazyTrixCooldownLock"', "cooldown panel lock button")
assertContains('lock.lockLabel = lock:CreateFontString', "asset-independent lock label")
assertContains('dragNote:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -36, -11)', "cooldown drag note left offset")
assertContains('ShirsLazyTrix.SaveCooldownPanelPosition', "saved cooldown panel position")
assertContains('"MERCHANT"', "merchant section heading")
assertContains('"Sell gray items", "autoSellGray"', "gray-only merchant checkbox")
assertContains('"Repair all gear", "autoRepairAll"', "automatic repair checkbox")
assertContains("Gray-only selling. Vendor actions stay independent.", "merchant boundary note")
assertContains('table.insert(UISpecialFrames, "ShirsLazyTrixSettingsFrame")', "Escape closes settings")
assertAbsent("repeatable", "repeatable controls must be removed")

if count('createCheckbox(') ~= 18 then
  error("UI must define exactly seventeen checkbox calls plus the helper", 2)
end

print("ui-minimal-family-style: PASS")
print("ui-movable-filled-minimap: PASS")
print("ui-ten-setting-structure: PASS")
print("ui-profession-cooldown-structure: PASS")
