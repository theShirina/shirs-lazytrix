-- Runtime construction and interaction checks for Shir's LazyTrix UI.

local root = arg and arg[1] or "."
local named = {}
local cursorX, cursorY = 100, 180

local function makeRegion(kind)
  local region = { kind = kind, shown = true }
  function region:SetText(value) self.text = value end
  function region:SetTextColor(...) self.textColor = arg end
  function region:SetFont(...) self.font = arg end
  function region:SetPoint(...) self.point = arg end
  function region:ClearAllPoints() self.point = nil end
  function region:SetAllPoints(value) self.allPoints = value or true end
  function region:SetWidth(value) self.width = value end
  function region:SetHeight(value) self.height = value end
  function region:SetJustifyH(value) self.justifyH = value end
  function region:SetTexture(...) self.texture = arg end
  function region:SetTexCoord(...) self.texCoord = arg end
  function region:SetVertexColor(...) self.vertexColor = arg end
  function region:Show() self.shown = true end
  function region:Hide() self.shown = false end
  return region
end

local function makeFrame(kind, name, parent, template)
  local frame = {
    kind = kind,
    name = name,
    parent = parent,
    template = template,
    shown = true,
    scripts = {},
    textures = {},
    fontStrings = {},
    frameLevel = 1,
  }
  function frame:SetWidth(value) self.width = value end
  function frame:SetHeight(value) self.height = value end
  function frame:SetPoint(...) self.point = arg end
  function frame:GetPoint() return unpack(self.point) end
  function frame:ClearAllPoints() self.point = nil end
  function frame:SetFrameStrata(value) self.strata = value end
  function frame:SetFrameLevel(value) self.frameLevel = value end
  function frame:GetFrameLevel() return self.frameLevel end
  function frame:SetToplevel(value) self.toplevel = value end
  function frame:SetMovable(value) self.movable = value end
  function frame:EnableMouse(value) self.mouseEnabled = value end
  function frame:SetClampedToScreen(value) self.clamped = value end
  function frame:RegisterForDrag(...) self.dragButtons = arg end
  function frame:RegisterForClicks(...) self.clickButtons = arg end
  function frame:SetScript(key, value) self.scripts[key] = value end
  function frame:GetScript(key) return self.scripts[key] end
  function frame:SetBackdrop(value) self.backdrop = value end
  function frame:SetBackdropColor(...) self.backdropColor = arg end
  function frame:SetBackdropBorderColor(...) self.backdropBorderColor = arg end
  function frame:SetHighlightTexture(value) self.highlightTexture = value end
  function frame:SetNormalTexture(value)
    self.normalTexture = makeRegion("Texture")
    self.normalTexture:SetTexture(value)
  end
  function frame:GetNormalTexture() return self.normalTexture end
  function frame:SetChecked(value) self.checked = value end
  function frame:GetChecked() return self.checked end
  function frame:SetMinMaxValues(low, high) self.minimum = low self.maximum = high end
  function frame:SetValueStep(value) self.valueStep = value end
  function frame:SetValue(value) self.value = value end
  function frame:GetValue() return self.value end
  function frame:StartMoving() self.moving = true end
  function frame:StopMovingOrSizing() self.moving = false end
  function frame:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow() end end
  function frame:Hide() self.shown = false end
  function frame:IsVisible() return self.shown end
  function frame:IsShown() return self.shown end
  function frame:CreateTexture(_, layer)
    local texture = makeRegion("Texture")
    texture.layer = layer
    table.insert(self.textures, texture)
    return texture
  end
  function frame:CreateFontString(_, layer, font)
    local text = makeRegion("FontString")
    text.layer = layer
    text.fontObject = font
    table.insert(self.fontStrings, text)
    return text
  end
  if name then
    named[name] = frame
    _G[name] = frame
  end
  if template == "UICheckButtonTemplate" and name then
    local label = makeRegion("FontString")
    named[name .. "Text"] = label
    _G[name .. "Text"] = label
  elseif template == "OptionsSliderTemplate" and name then
    for _, suffix in ipairs({ "Low", "High", "Text" }) do
      local label = makeRegion("FontString")
      named[name .. suffix] = label
      _G[name .. suffix] = label
    end
  end
  return frame
end

function CreateFrame(kind, name, parent, template)
  return makeFrame(kind, name, parent, template)
end
function getglobal(name) return named[name] end
function GetCursorPosition() return cursorX, cursorY end

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UISpecialFrames = {}
UIParent = makeFrame("Frame", "UIParent")
function UIParent:GetEffectiveScale() return 1 end
function UIParent:GetScale() return 1 end
Minimap = makeFrame("Frame", "Minimap", UIParent)
Minimap.frameLevel = 4
function Minimap:GetCenter() return 100, 100 end
GameTooltip = { lines = {} }
function GameTooltip:SetOwner(...) self.owner = arg end
function GameTooltip:SetText(text) self.lines = { text } end
function GameTooltip:AddLine(text) table.insert(self.lines, text) end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown = false end

ShirsLazyTrix = {}
local trainerRefreshes = 0
local cooldownClicks = {}
local savedCooldownPosition = nil
local insideInstance = false
function IsInInstance() return insideInstance, insideInstance and "party" or nil end
ShirsLazyTrix.RefreshTrainerFeature = function() trainerRefreshes = trainerRefreshes + 1 end
ShirsLazyTrix.GetCooldownDefinitions = function()
  return {
    mooncloth = { label = "Mooncloth" },
    arcanite = { label = "Transmute: Arcanite" },
    salt = { label = "Salt Shaker" },
  }
end
ShirsLazyTrix.GetCurrentCooldowns = function()
  return {
    mooncloth = { known = true, readyAt = 1 },
    arcanite = { known = true, readyAt = 2 },
  }
end
ShirsLazyTrix.FormatCooldownStatus = function(entry)
  if not entry then return "Not known" end
  if entry.readyAt == 1 then return "Ready" end
  return "1d 2h"
end
local accountCooldownTick = 0
ShirsLazyTrix.GetCooldownCharacterStatuses = function(key)
  if key ~= "mooncloth" then return {} end
  return {
    { owner = "Alfa", status = accountCooldownTick == 0 and "1m 5s" or "1m 4s" },
    { owner = "Beta", status = "Ready" },
  }
end
ShirsLazyTrix.GetCooldownPanelPosition = function() return "TOPLEFT", "TOPLEFT", 40, -60 end
ShirsLazyTrix.SaveCooldownPanelPosition = function(point, relativePoint, x, y)
  savedCooldownPosition = { point, relativePoint, x, y }
end
ShirsLazyTrix.ClickProfessionCooldown = function(key) table.insert(cooldownClicks, key) end
local lootRefreshes, collectorRefreshes, trayToggles, collectorInitializations, buttonSizeRefreshes = 0, 0, 0, 0, 0
ShirsLazyTrix.NormalizeLootRows = function(value) return math.max(4, math.min(12, math.floor((tonumber(value) or 4) + 0.5))) end
ShirsLazyTrix.ApplyLootRows = function(value) ShirsLazyTrixDB.lootRows = ShirsLazyTrix.NormalizeLootRows(value) lootRefreshes = lootRefreshes + 1 return true end
ShirsLazyTrix.NormalizeMinimapButtonSize = function(value) return math.max(18, math.min(32, math.floor((tonumber(value) or 24) + 0.5))) end
ShirsLazyTrix.ApplyMinimapButtonSize = function(value) ShirsLazyTrixDB.minimapButtonSize = ShirsLazyTrix.NormalizeMinimapButtonSize(value) buttonSizeRefreshes = buttonSizeRefreshes + 1 return true end
ShirsLazyTrix.RefreshMinimapButtonCollector = function() collectorRefreshes = collectorRefreshes + 1 return true end
ShirsLazyTrix.ToggleMinimapButtonTray = function() trayToggles = trayToggles + 1 return true end
ShirsLazyTrix.InitializeMinimapButtonCollector = function(button) collectorInitializations = collectorInitializations + 1 return button end
ShirsLazyTrixDB = { turnIn = true, pickUp = false, automationOnShift = false, autoSellGray = false, autoRepairAll = false, autoAcceptOpenWorldRes = false, autoRemoveImmolationOnStealth = false, expandTrainers = false, trainAll = false, autoOpenTrainers = false, showCooldownPanel = false, cooldownPanelLocked = false, hideCooldownPanelInCombat = false, notifyOtherMooncloth = true, notifyOtherArcanite = true, notifyOtherSalt = true, showItemIDs = false, lootRows = 4, consolidateMinimapButtons = false, minimapButtonSize = 24, minimapAngle = 220 }

dofile(root .. "/ShirsLazyTrix_UI.lua")
ShirsLazyTrix.CreateUI()

local settings = named.ShirsLazyTrixSettingsFrame
local minimap = named.ShirsLazyTrixMinimapButton
local cooldownPanel = named.ShirsLazyTrixCooldownPanel
if not settings or not minimap or not cooldownPanel then error("UI frames were not constructed", 2) end
if settings.width ~= 620 or settings.height ~= 510 then error("compact two-column settings geometry mismatch", 2) end
if settings.point[5] ~= 0 then error("settings panel must use a viewport-safe center anchor", 2) end
if not settings.backdrop or settings.backdrop.bgFile ~= "Interface\\Tooltips\\UI-Tooltip-Background" then error("settings backdrop mismatch", 2) end
if settings.backdropColor[1] ~= 0.025 or settings.backdropBorderColor[3] ~= 0.9 then error("settings palette mismatch", 2) end
if minimap.width ~= 32 or minimap.height ~= 32 then error("minimap button geometry mismatch", 2) end
if table.getn(minimap.textures) ~= 2 then error("minimap button must have icon and border textures", 2) end
local icon = minimap.textures[1]
local border = minimap.textures[2]
if icon.layer ~= "ARTWORK" or icon.width ~= 20 or icon.height ~= 20 or icon.texture[1] ~= "Interface\\AddOns\\ShirsLazyTrix\\LazyTrixIcon" then error("custom minimap icon mismatch", 2) end
if border.width ~= 52 or border.height ~= 52 or border.texture[1] ~= "Interface\\Minimap\\MiniMap-TrackingBorder" then error("minimap border mismatch", 2) end
if not minimap.highlightTexture then error("minimap highlight missing", 2) end
if not minimap.scripts.OnDragStart or not minimap.scripts.OnDragStop then error("minimap drag handlers missing", 2) end
if collectorInitializations ~= 1 then error("minimap collector was not initialized with the launcher", 2) end
if cooldownPanel.width ~= 250 or cooldownPanel.height ~= 112 then error("cooldown panel geometry mismatch", 2) end
if cooldownPanel:IsVisible() then error("disabled cooldown panel should start hidden", 2) end
if not cooldownPanel.movable or not cooldownPanel.clamped or not cooldownPanel.scripts.OnDragStart or not cooldownPanel.scripts.OnDragStop then
  error("cooldown panel drag contract missing", 2)
end
local cooldownLock = named.ShirsLazyTrixCooldownLock
if not cooldownLock then error("cooldown panel lock button missing", 2) end
if not cooldownLock.lockLabel or cooldownLock.lockLabel.text ~= "U" then error("cooldown panel unlock label missing", 2) end
if cooldownPanel.fontStrings[2].point[4] ~= -36 then error("cooldown drag text was not moved left for the lock button", 2) end

minimap.scripts.OnDragStart()
if not minimap.scripts.OnUpdate then error("drag did not start position updates", 2) end
minimap.scripts.OnUpdate()
if math.abs(ShirsLazyTrixDB.minimapAngle - 90) > 0.01 then error("minimap angle was not saved from cursor", 2) end
if not minimap.point or math.abs(minimap.point[4]) > 0.01 or math.abs(minimap.point[5] - 80) > 0.01 then error("minimap position did not follow saved angle", 2) end
minimap.scripts.OnDragStop()
if minimap.scripts.OnUpdate ~= nil then error("drag update was not cleared", 2) end

minimap.scripts.OnEnter()
if GameTooltip.lines[4] ~= "Drag: Move this button" then error("drag tooltip line missing", 2) end
minimap.scripts.OnLeave()
if GameTooltip.shown then error("tooltip did not hide", 2) end

if settings:IsVisible() then error("settings should start hidden", 2) end
this = minimap
minimap.scripts.OnClick()
if not settings:IsVisible() then error("minimap click did not open settings", 2) end
local turnIn = named.ShirsLazyTrixTurnIn
local pickUp = named.ShirsLazyTrixPickUp
local shiftAutomation = named.ShirsLazyTrixShiftAutomation
local autoSellGray = named.ShirsLazyTrixAutoSellGray
local autoRepairAll = named.ShirsLazyTrixAutoRepairAll
local autoAcceptOpenWorldRes = named.ShirsLazyTrixAutoAcceptOpenWorldRes
local autoRemoveImmolationOnStealth = named.ShirsLazyTrixAutoRemoveImmolationOnStealth
local expandTrainers = named.ShirsLazyTrixExpandTrainers
local trainAll = named.ShirsLazyTrixTrainAll
local autoOpenTrainers = named.ShirsLazyTrixAutoOpenTrainers
local showCooldownPanel = named.ShirsLazyTrixShowCooldownPanel
local hideCooldownInCombat = named.ShirsLazyTrixHideCooldownPanelInCombat
local notifyOtherMooncloth = named.ShirsLazyTrixNotifyOtherMooncloth
local notifyOtherArcanite = named.ShirsLazyTrixNotifyOtherArcanite
local notifyOtherSalt = named.ShirsLazyTrixNotifyOtherSalt
local showItemIDs = named.ShirsLazyTrixShowItemIDs
local consolidateMinimapButtons = named.ShirsLazyTrixConsolidateMinimapButtons
local lootRowsSlider = named.ShirsLazyTrixLootRowsSlider
local minimapButtonSizeSlider = named.ShirsLazyTrixMinimapButtonSizeSlider
if not shiftAutomation then error("Shift-required automation checkbox missing", 2) end
if not autoSellGray then error("automatic gray sale checkbox missing", 2) end
if not autoRepairAll then error("automatic repair checkbox missing", 2) end
if not autoAcceptOpenWorldRes then error("open-world resurrection checkbox missing", 2) end
if not autoRemoveImmolationOnStealth then error("stealth immolation cleanup checkbox missing", 2) end
if not expandTrainers then error("expanded trainer checkbox missing", 2) end
if not trainAll then error("Train All checkbox missing", 2) end
if not autoOpenTrainers then error("automatic trainer gossip checkbox missing", 2) end
if not showCooldownPanel then error("profession cooldown panel checkbox missing", 2) end
if not hideCooldownInCombat then error("cooldown combat-hide checkbox missing", 2) end
if not notifyOtherMooncloth or not notifyOtherArcanite or not notifyOtherSalt then error("individual other-character reminder checkboxes missing", 2) end
if not showItemIDs then error("item-ID tooltip checkbox missing", 2) end
if not consolidateMinimapButtons then error("minimap collector checkbox missing", 2) end
if not lootRowsSlider or lootRowsSlider.minimum ~= 4 or lootRowsSlider.maximum ~= 12 or lootRowsSlider.valueStep ~= 1 then error("stock loot row slider missing", 2) end
if not minimapButtonSizeSlider or minimapButtonSizeSlider.minimum ~= 18 or minimapButtonSizeSlider.maximum ~= 32 or minimapButtonSizeSlider.valueStep ~= 1 then error("collected minimap button size slider missing", 2) end
if turnIn.point[4] ~= 24 or autoAcceptOpenWorldRes.point[4] ~= 24 or autoSellGray.point[4] ~= 24 then error("left settings column anchors mismatch", 2) end
if expandTrainers.point[4] ~= 326 or showCooldownPanel.point[4] ~= 326 or showItemIDs.point[4] ~= 326 then error("right settings column anchors mismatch", 2) end
if lootRowsSlider.point[4] ~= 334 or minimapButtonSizeSlider.point[4] ~= 480 then error("compact slider columns mismatch", 2) end
if lootRowsSlider.point[5] < -settings.height + 25 then error("stock loot row slider extends beyond the settings panel", 2) end
if minimapButtonSizeSlider.point[5] < -settings.height + 25 then error("minimap button size slider extends beyond the settings panel", 2) end
if turnIn.checked ~= 1 or pickUp.checked ~= nil or shiftAutomation.checked ~= nil or autoSellGray.checked ~= nil or autoRepairAll.checked ~= nil or autoAcceptOpenWorldRes.checked ~= nil or autoRemoveImmolationOnStealth.checked ~= nil or expandTrainers.checked ~= nil or trainAll.checked ~= nil or autoOpenTrainers.checked ~= nil or showCooldownPanel.checked ~= nil or hideCooldownInCombat.checked ~= nil or notifyOtherMooncloth.checked ~= 1 or notifyOtherArcanite.checked ~= 1 or notifyOtherSalt.checked ~= 1 or showItemIDs.checked ~= nil then error("settings did not refresh checkbox states", 2) end
turnIn.checked = nil
this = turnIn
turnIn.scripts.OnClick()
if ShirsLazyTrixDB.turnIn ~= false then error("turn-in checkbox did not save false", 2) end
shiftAutomation.checked = 1
this = shiftAutomation
shiftAutomation.scripts.OnClick()
if ShirsLazyTrixDB.automationOnShift ~= true then error("Shift-required automation checkbox did not save true", 2) end
autoSellGray.checked = 1
this = autoSellGray
autoSellGray.scripts.OnClick()
if ShirsLazyTrixDB.autoSellGray ~= true then error("automatic gray sale checkbox did not save true", 2) end
autoRepairAll.checked = 1
this = autoRepairAll
autoRepairAll.scripts.OnClick()
if ShirsLazyTrixDB.autoRepairAll ~= true then error("automatic repair checkbox did not save true", 2) end
autoAcceptOpenWorldRes.checked = 1
this = autoAcceptOpenWorldRes
autoAcceptOpenWorldRes.scripts.OnClick()
if ShirsLazyTrixDB.autoAcceptOpenWorldRes ~= true then error("open-world resurrection checkbox did not save true", 2) end
autoRemoveImmolationOnStealth.checked = 1
this = autoRemoveImmolationOnStealth
autoRemoveImmolationOnStealth.scripts.OnClick()
if ShirsLazyTrixDB.autoRemoveImmolationOnStealth ~= true then error("stealth immolation cleanup checkbox did not save true", 2) end
expandTrainers.checked = 1
this = expandTrainers
expandTrainers.scripts.OnClick()
if ShirsLazyTrixDB.expandTrainers ~= true or ShirsLazyTrixDB.trainAll ~= false then error("expanded trainer checkbox did not save independently", 2) end
trainAll.checked = 1
this = trainAll
trainAll.scripts.OnClick()
if ShirsLazyTrixDB.trainAll ~= true or ShirsLazyTrixDB.expandTrainers ~= true then error("Train All checkbox did not save independently", 2) end
if trainerRefreshes ~= 2 then error("trainer setting clicks did not refresh the feature independently", 2) end
autoOpenTrainers.checked = 1
this = autoOpenTrainers
autoOpenTrainers.scripts.OnClick()
if ShirsLazyTrixDB.autoOpenTrainers ~= true then error("automatic trainer gossip checkbox did not save true", 2) end

showCooldownPanel.checked = 1
this = showCooldownPanel
showCooldownPanel.scripts.OnClick()
if ShirsLazyTrixDB.showCooldownPanel ~= true or not cooldownPanel:IsVisible() then
  error("cooldown checkbox did not show the panel", 2)
end

local moonclothRow = named.ShirsLazyTrixCooldownMooncloth
local arcaniteRow = named.ShirsLazyTrixCooldownArcanite
local saltRow = named.ShirsLazyTrixCooldownSalt
if not moonclothRow or not arcaniteRow or not saltRow then error("cooldown rows missing", 2) end
if moonclothRow.status.text ~= "Ready" or arcaniteRow.status.text ~= "1d 2h" or saltRow.status.text ~= "Not known" then
  error("cooldown row status text mismatch", 2)
end
this = moonclothRow
moonclothRow.scripts.OnEnter()
if GameTooltip.lines[5] ~= "Alfa: 1m 5s" or GameTooltip.lines[6] ~= "Beta: Ready" then
  error("account-wide cooldown hover lines missing", 2)
end
accountCooldownTick = 1
ShirsLazyTrix.RefreshCooldownPanel()
if GameTooltip.lines[5] ~= "Alfa: 1m 4s" then
  error("account-wide cooldown hover did not refresh live", 2)
end
moonclothRow.scripts.OnLeave()
this = moonclothRow
moonclothRow.scripts.OnClick()
if table.getn(cooldownClicks) ~= 1 or cooldownClicks[1] ~= "mooncloth" then error("Mooncloth row did not request one craft", 2) end

cooldownPanel.point = { "TOPLEFT", UIParent, "TOPLEFT", 75, -95 }
this = cooldownPanel
cooldownPanel.scripts.OnDragStart()
if not cooldownPanel.moving then error("cooldown panel drag did not start", 2) end
cooldownPanel.scripts.OnDragStop()
if cooldownPanel.moving then error("cooldown panel drag did not stop", 2) end
if not savedCooldownPosition or savedCooldownPosition[1] ~= "TOPLEFT" or savedCooldownPosition[2] ~= "TOPLEFT" or savedCooldownPosition[3] ~= 75 or savedCooldownPosition[4] ~= -95 then
  error("cooldown panel position was not saved", 2)
end

this = cooldownLock
cooldownLock.scripts.OnClick()
if ShirsLazyTrixDB.cooldownPanelLocked ~= true or cooldownPanel.movable ~= false then error("cooldown panel did not lock", 2) end
if cooldownLock.lockLabel.text ~= "L" then error("cooldown panel lock label did not update", 2) end
cooldownPanel.moving = false
this = cooldownPanel
cooldownPanel.scripts.OnDragStart()
if cooldownPanel.moving then error("locked cooldown panel started moving", 2) end
this = cooldownLock
cooldownLock.scripts.OnClick()
if ShirsLazyTrixDB.cooldownPanelLocked ~= false or cooldownPanel.movable ~= true then error("cooldown panel did not unlock", 2) end
if cooldownLock.lockLabel.text ~= "U" then error("cooldown panel unlock label did not return", 2) end

hideCooldownInCombat.checked = 1
this = hideCooldownInCombat
hideCooldownInCombat.scripts.OnClick()
if ShirsLazyTrixDB.hideCooldownPanelInCombat ~= true then error("combat-hide checkbox did not save true", 2) end
notifyOtherMooncloth.checked = nil
this = notifyOtherMooncloth
notifyOtherMooncloth.scripts.OnClick()
if ShirsLazyTrixDB.notifyOtherMooncloth ~= false or ShirsLazyTrixDB.notifyOtherArcanite ~= true or ShirsLazyTrixDB.notifyOtherSalt ~= true then error("Mooncloth reminder checkbox did not save independently", 2) end
notifyOtherArcanite.checked = nil
this = notifyOtherArcanite
notifyOtherArcanite.scripts.OnClick()
if ShirsLazyTrixDB.notifyOtherArcanite ~= false or ShirsLazyTrixDB.notifyOtherSalt ~= true then error("Arcanite reminder checkbox did not save independently", 2) end
notifyOtherSalt.checked = nil
this = notifyOtherSalt
notifyOtherSalt.scripts.OnClick()
if ShirsLazyTrixDB.notifyOtherSalt ~= false then error("Salt Shaker reminder checkbox did not save independently", 2) end
showItemIDs.checked = 1
this = showItemIDs
showItemIDs.scripts.OnClick()
if ShirsLazyTrixDB.showItemIDs ~= true then error("item-ID tooltip checkbox did not save true", 2) end
lootRowsSlider.value = 9
this = lootRowsSlider
lootRowsSlider.scripts.OnValueChanged()
if ShirsLazyTrixDB.lootRows ~= 9 or lootRefreshes ~= 1 then error("stock loot slider did not apply nine rows", 2) end
minimapButtonSizeSlider.value = 20
this = minimapButtonSizeSlider
minimapButtonSizeSlider.scripts.OnValueChanged()
if ShirsLazyTrixDB.minimapButtonSize ~= 20 or buttonSizeRefreshes ~= 1 then error("minimap button size slider did not apply twenty pixels", 2) end
consolidateMinimapButtons.checked = 1
this = consolidateMinimapButtons
consolidateMinimapButtons.scripts.OnClick()
if ShirsLazyTrixDB.consolidateMinimapButtons ~= true or collectorRefreshes ~= 1 then error("minimap collector checkbox did not apply", 2) end
settings:Hide()
arg1 = "LeftButton"
this = minimap
minimap.scripts.OnClick()
if trayToggles ~= 1 or settings:IsVisible() then error("enabled minimap collector left click did not open the tray", 2) end
arg1 = "RightButton"
minimap.scripts.OnClick()
if not settings:IsVisible() then error("minimap right click did not open LazyTrix settings", 2) end
arg1 = nil
ShirsLazyTrix.SetCooldownPanelCombatState(true)
if cooldownPanel:IsVisible() then error("cooldown panel stayed visible in combat", 2) end
ShirsLazyTrix.SetCooldownPanelCombatState(false)
if not cooldownPanel:IsVisible() then error("cooldown panel did not return after combat", 2) end
insideInstance = true
ShirsLazyTrix.RefreshCooldownPanelVisibility()
if cooldownPanel:IsVisible() then error("cooldown panel stayed visible inside an instance", 2) end
insideInstance = false
ShirsLazyTrix.RefreshCooldownPanelVisibility()
if not cooldownPanel:IsVisible() then error("cooldown panel did not return after leaving an instance", 2) end

print("ui-runtime-construction: PASS")
print("ui-runtime-minimap-drag: PASS")
print("ui-runtime-checkbox: PASS")
print("ui-runtime-cooldown-panel: PASS")
