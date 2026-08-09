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
ShirsLazyTrixDB = { turnIn = true, pickUp = false, automationOnShift = false, autoSellGray = false, autoRepairAll = false, autoAcceptOpenWorldRes = false, autoRemoveImmolationOnStealth = false, enhanceTrainers = false, autoOpenTrainers = false, minimapAngle = 220 }

dofile(root .. "/ShirsLazyTrix_UI.lua")
ShirsLazyTrix.CreateUI()

local settings = named.ShirsLazyTrixSettingsFrame
local minimap = named.ShirsLazyTrixMinimapButton
if not settings or not minimap then error("UI frames were not constructed", 2) end
if settings.width ~= 340 or settings.height ~= 480 then error("minimal settings geometry mismatch", 2) end
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
local enhanceTrainers = named.ShirsLazyTrixEnhanceTrainers
local autoOpenTrainers = named.ShirsLazyTrixAutoOpenTrainers
if not shiftAutomation then error("Shift-required automation checkbox missing", 2) end
if not autoSellGray then error("automatic gray sale checkbox missing", 2) end
if not autoRepairAll then error("automatic repair checkbox missing", 2) end
if not autoAcceptOpenWorldRes then error("open-world resurrection checkbox missing", 2) end
if not autoRemoveImmolationOnStealth then error("stealth immolation cleanup checkbox missing", 2) end
if not enhanceTrainers then error("enhanced trainer checkbox missing", 2) end
if not autoOpenTrainers then error("automatic trainer gossip checkbox missing", 2) end
if turnIn.checked ~= 1 or pickUp.checked ~= nil or shiftAutomation.checked ~= nil or autoSellGray.checked ~= nil or autoRepairAll.checked ~= nil or autoAcceptOpenWorldRes.checked ~= nil or autoRemoveImmolationOnStealth.checked ~= nil or enhanceTrainers.checked ~= nil or autoOpenTrainers.checked ~= nil then error("settings did not refresh checkbox states", 2) end
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
enhanceTrainers.checked = 1
this = enhanceTrainers
enhanceTrainers.scripts.OnClick()
if ShirsLazyTrixDB.enhanceTrainers ~= true then error("enhanced trainer checkbox did not save true", 2) end
autoOpenTrainers.checked = 1
this = autoOpenTrainers
autoOpenTrainers.scripts.OnClick()
if ShirsLazyTrixDB.autoOpenTrainers ~= true then error("automatic trainer gossip checkbox did not save true", 2) end

print("ui-runtime-construction: PASS")
print("ui-runtime-minimap-drag: PASS")
print("ui-runtime-checkbox: PASS")
