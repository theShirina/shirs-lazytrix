-- Optional minimap-button collector tests for Lua 5.0.3.
local root = arg and arg[1] or "."
local named = {}

local function texture(owner, width, height)
  local value = { owner = owner, point = { "CENTER", owner, "CENTER", 1, 2 }, width = width or 32, height = height or 32, shown = true }
  function value:GetObjectType() return "Texture" end
  function value:GetPoint() return unpack(self.point) end
  function value:SetPoint(...) self.point = arg end
  function value:ClearAllPoints() self.point = nil self.allPoints = nil end
  function value:SetAllPoints(target) self.allPoints = target end
  function value:GetWidth() return self.width end
  function value:GetHeight() return self.height end
  function value:SetWidth(v) self.width = v end
  function value:SetHeight(v) self.height = v end
  function value:IsShown() return self.shown end
  function value:Show() self.shown = true end
  function value:Hide() self.shown = false end
  return value
end

local function frame(name, parent)
  local value = { name = name, parent = parent, shown = true, scripts = {}, point = { "CENTER", parent, "CENTER", 3, 4 }, scale = 0.8, frameLevel = 4 }
  function value:GetName() return self.name end
  function value:GetParent() return self.parent end
  function value:SetParent(newParent) self.parent = newParent end
  function value:GetPoint() return unpack(self.point) end
  function value:SetPoint(...) self.point = arg end
  function value:ClearAllPoints() self.point = nil end
  function value:GetWidth() return self.width or 32 end
  function value:GetHeight() return self.height or 32 end
  function value:SetWidth(v) self.width = v end
  function value:SetHeight(v) self.height = v end
  function value:GetScale() return self.scale end
  function value:SetScale(v) self.scale = v end
  function value:GetFrameLevel() return self.frameLevel end
  function value:SetFrameLevel(v) self.frameLevel = v end
  function value:GetFrameStrata() return self.strata end
  function value:SetFrameStrata(v) self.strata = v end
  function value:GetScript(key) return self.scripts[key] end
  function value:SetScript(key, callback) self.scripts[key] = callback end
  function value:IsShown() return self.shown end
  function value:Show() self.shown = true end
  function value:Hide() self.shown = false end
  function value:SetBackdrop(v) self.backdrop = v end
  function value:SetBackdropColor(...) self.backdropColor = arg end
  function value:SetBackdropBorderColor(...) self.backdropBorderColor = arg end
  function value:GetNormalTexture() return self.normalTexture end
  function value:GetPushedTexture() return self.pushedTexture end
  function value:GetHighlightTexture() return self.highlightTexture end
  function value:GetDisabledTexture() return self.disabledTexture end
  function value:GetRegions() return unpack(self.regions or {}) end
  named[name] = value
  return value
end

UIParent = frame("UIParent")
Minimap = frame("Minimap", UIParent)
MinimapBackdrop = frame("MinimapBackdrop", UIParent)
local addonOne = frame("AddonOneButton", Minimap)
addonOne.scripts.OnClick = function() end
addonOne.normalTexture = texture(addonOne)
addonOne.iconRegion = texture(addonOne, 22, 22)
addonOne.borderRegion = texture(addonOne, 54, 54)
addonOne.regions = { addonOne.normalTexture, addonOne.iconRegion, addonOne.borderRegion }
local addonTwo = frame("AddonTwoIcon", MinimapBackdrop)
addonTwo.scripts.OnMouseDown = function() end
local addonHidden = frame("AddonHiddenButton", Minimap)
addonHidden.scripts.OnClick = function() end
addonHidden.shown = false
local atlasWrapper = frame("AtlasLootMinimapButtonFrame", Minimap)
atlasWrapper.strata = "LOW"
local atlasButton = frame("AtlasLootMinimapButton", atlasWrapper)
atlasButton.strata = "LOW"
atlasButton.frameLevel = 5
atlasButton.scripts.OnClick = function() end
atlasButton.normalTexture = texture(atlasButton)
function atlasWrapper:GetScript(key)
  if key == "OnClick" then error("AtlasLootMinimapButtonFrame doesn't have a \"OnClick\" script") end
  return self.scripts[key]
end
function atlasWrapper:GetChildren() return atlasButton end
local ccpWrapper = frame("CCPButtonFrame", Minimap)
ccpWrapper.strata = "LOW"
local ccpButton = frame("AtlasButton", ccpWrapper)
ccpButton.width = 24
ccpButton.height = 24
ccpButton.strata = "LOW"
ccpButton.frameLevel = 5
ccpButton.scripts.OnClick = function() end
ccpButton.normalTexture = texture(ccpButton)
function ccpWrapper:GetChildren() return ccpButton end
local malformed = frame("MalformedButton", Minimap)
malformed.scripts.OnClick = function() end
malformed.width = 0 / 0
local stock = frame("MiniMapTrackingFrame", Minimap)
stock.scripts.OnClick = function() end
local launcher = frame("ShirsLazyTrixMinimapButton", Minimap)
launcher.scripts.OnClick = function() end
function Minimap:GetChildren() return addonOne, addonHidden, atlasWrapper, ccpWrapper, malformed, stock, launcher end
function MinimapBackdrop:GetChildren() return addonTwo end
function CreateFrame(kind, name, parent)
  local value = frame(name or ("Anonymous" .. tostring(table.getn(named) + 1)), parent)
  value.kind = kind
  return value
end
function getglobal(name) return named[name] end

ShirsLazyTrix = {}
ShirsLazyTrixDB = { consolidateMinimapButtons = true, minimapButtonSize = 24 }
dofile(root .. "/ShirsLazyTrix_MinimapButtons.lua")

local function assertEqual(actual, expected, message)
  if actual ~= expected then error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

local tray = ShirsLazyTrix.InitializeMinimapButtonCollector(launcher)
if not tray then error("collector tray was not created", 2) end
assertEqual(ShirsLazyTrix.RefreshMinimapButtonCollector(), true, "collector refresh")
assertEqual(addonOne.parent, tray, "first addon button parent")
assertEqual(addonTwo.parent, tray, "second addon button parent")
assertEqual(addonHidden.parent, tray, "initially hidden addon button collected")
assertEqual(atlasWrapper.parent, tray, "AtlasLoot wrapper with clickable child collected without script error")
assertEqual(atlasButton.parent, atlasWrapper, "AtlasLoot child button stays inside its wrapper")
assertEqual(ccpWrapper.parent, tray, "CCP wrapper collected")
assertEqual(malformed.parent, Minimap, "malformed-size minimap button excluded")
assertEqual(stock.parent, Minimap, "stock minimap frame excluded")
assertEqual(launcher.parent, Minimap, "LazyTrix launcher excluded")
assertEqual(addonOne.scale, 1, "collected direct button uses normalized scale")
assertEqual(addonOne.width, 24, "collected direct button width matches tray cell")
assertEqual(addonOne.height, 24, "collected direct button height matches tray cell")
assertEqual(atlasWrapper.strata, "HIGH", "low-strata wrapper raised above tray background")
assertEqual(atlasWrapper.width, 24, "AtlasLoot wrapper width matches tray cell")
assertEqual(atlasButton.width, 24, "AtlasLoot child width matches tray cell")
assertEqual(atlasButton.height, 24, "AtlasLoot child height matches tray cell")
assertEqual(atlasButton.strata, "HIGH", "AtlasLoot clickable child raised above tray")
assertEqual(atlasButton.frameLevel, 22, "AtlasLoot clickable child frame level raised above tray")
assertEqual(ccpWrapper.strata, "HIGH", "CCP wrapper raised above tray background")
assertEqual(ccpButton.scale, 1, "CCP child uses normalized scale")
assertEqual(ccpButton.width, 24, "CCP child width matches tray cell")
assertEqual(ccpButton.strata, "HIGH", "CCP clickable child raised above tray")
assertEqual(addonOne.normalTexture.width, 20, "direct normal texture uses common artwork inset")
assertEqual(atlasButton.normalTexture.width, 20, "AtlasLoot texture uses common artwork inset")
assertEqual(addonOne.iconRegion.width, 20, "anonymous icon region uses common artwork inset")
assertEqual(addonOne.iconRegion.point[1], "CENTER", "anonymous icon region centered")
assertEqual(addonOne.borderRegion.shown, false, "oversized tracking border hidden inside collector tray")
assertEqual(addonOne.point[1], "TOPLEFT", "collected button tray anchor")
addonOne.scale = 0.5
addonOne.point = { "CENTER", Minimap, "CENTER", 99, 99 }
addonHidden.shown = true
assertEqual(ShirsLazyTrix.RefreshMinimapButtonCollector(), true, "collector periodic relayout")
assertEqual(addonOne.scale, 1, "collector restores normalized scale after addon mutation")
assertEqual(addonOne.point[1], "TOPLEFT", "collector restores tray anchor after addon mutation")
assertEqual(addonHidden.point[1], "TOPLEFT", "newly shown collected button enters tray layout")
assertEqual(tray.width, 140, "five-button compact tray width")
assertEqual(tray.height, 36, "single-row compact tray height")
assertEqual(ShirsLazyTrix.ApplyMinimapButtonSize(20), true, "collected button size applies live")
assertEqual(ShirsLazyTrixDB.minimapButtonSize, 20, "collected button size saved")
assertEqual(addonOne.width, 20, "direct button follows selected size")
assertEqual(atlasButton.width, 20, "nested clickable child follows selected size")
assertEqual(atlasButton.normalTexture.width, 16, "artwork inset follows selected size")
assertEqual(tray.width, 120, "five-button selected-size tray width")
assertEqual(tray.height, 32, "selected-size tray height")

assertEqual(ShirsLazyTrix.ToggleMinimapButtonTray(), true, "collector tray opens")
assertEqual(tray.shown, true, "collector tray shown")
assertEqual(ShirsLazyTrix.ToggleMinimapButtonTray(), false, "collector tray closes")
assertEqual(tray.shown, false, "collector tray hidden")

ShirsLazyTrixDB.consolidateMinimapButtons = false
assertEqual(ShirsLazyTrix.RefreshMinimapButtonCollector(), true, "collector disable restoration")
assertEqual(addonOne.parent, Minimap, "first addon button parent restored")
assertEqual(addonTwo.parent, MinimapBackdrop, "second addon button parent restored")
assertEqual(addonOne.scale, 0.8, "first addon button scale restored")
assertEqual(addonOne.width, 32, "first addon button width restored")
assertEqual(addonOne.height, 32, "first addon button height restored")
assertEqual(addonOne.point[1], "CENTER", "first addon button anchor restored")
assertEqual(atlasWrapper.strata, "LOW", "AtlasLoot wrapper strata restored")
assertEqual(atlasButton.width, 32, "AtlasLoot child width restored")
assertEqual(atlasButton.strata, "LOW", "AtlasLoot child strata restored")
assertEqual(atlasButton.frameLevel, 5, "AtlasLoot child frame level restored")
assertEqual(ccpWrapper.strata, "LOW", "CCP wrapper strata restored")
assertEqual(ccpButton.scale, 0.8, "CCP child scale restored")
assertEqual(ccpButton.width, 24, "CCP child width restored")
assertEqual(ccpButton.strata, "LOW", "CCP child strata restored")
assertEqual(addonOne.normalTexture.point[1], "CENTER", "direct button texture anchor restored")
assertEqual(atlasButton.normalTexture.point[1], "CENTER", "AtlasLoot texture anchor restored")
assertEqual(addonOne.iconRegion.width, 22, "anonymous icon width restored")
assertEqual(addonOne.borderRegion.width, 54, "oversized border width restored")
assertEqual(addonOne.borderRegion.shown, true, "oversized border visibility restored")

pfUI = { addonbuttons = {} }
ShirsLazyTrixDB.consolidateMinimapButtons = true
assertEqual(ShirsLazyTrix.RefreshMinimapButtonCollector(), false, "active pfUI collector conflict")
assertEqual(addonOne.parent, Minimap, "pfUI conflict leaves button untouched")
assertEqual(ShirsLazyTrixDB.consolidateMinimapButtons, false, "collector conflict switches the option back off")

print("minimap-button-collector: PASS")
