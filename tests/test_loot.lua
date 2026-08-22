-- Stock Blizzard loot-row expansion tests for Lua 5.0.3.
local root = arg and arg[1] or "."
local named = {}
local updateCalls = 0

local function region(kind, texture, text)
  local value = { kind = kind, texture = texture, text = text, shown = true }
  function value:GetObjectType() return self.kind end
  function value:GetTexture() return self.texture end
  function value:SetTexture(path) self.texture = path end
  function value:GetText() return self.text end
  function value:SetPoint(...) self.point = arg end
  function value:ClearAllPoints() self.point = nil end
  function value:SetWidth(width) self.width = width end
  function value:SetHeight(height) self.height = height end
  function value:SetTexCoord(...) self.texCoord = arg end
  function value:Show() self.shown = true end
  function value:Hide() self.shown = false end
  return value
end

local function frame(name)
  local value = { name = name, shown = true }
  function value:SetID(id) self.id = id end
  function value:SetPoint(...) self.point = arg end
  function value:ClearAllPoints() self.point = nil end
  function value:SetHeight(height) self.height = height end
  function value:GetHeight() return self.height end
  function value:SetScale(scale) self.scale = scale end
  function value:GetScale() return self.scale end
  function value:GetRegions() return unpack(self.regions or {}) end
  function value:CreateTexture(textureName, layer)
    local texture = region("Texture")
    texture.name = textureName
    texture.layer = layer
    return texture
  end
  function value:Show() self.shown = true end
  function value:Hide() self.shown = false end
  function value:IsShown() return self.shown end
  return value
end

LootFrame = frame("LootFrame")
LootFrame.height = 256
LootFrame.page = 4
local stockPanel = region("Texture", "Interface\\LootFrame\\UI-LootPanel")
local itemsLabel = region("FontString", nil, "Items")
LootFrame.regions = { stockPanel, itemsLabel }
ITEMS = "Items"
for index = 1, 4 do named["LootButton" .. index] = frame("LootButton" .. index) end
function getglobal(name) return named[name] end
function CreateFrame(kind, name, parent, template)
  local value = frame(name)
  value.kind = kind
  value.parent = parent
  value.template = template
  named[name] = value
  return value
end
function LootFrame_Update() updateCalls = updateCalls + 1 end
function GetNumLootItems() return 10 end
LOOTFRAME_NUMBUTTONS = 4
ShirsLazyTrix = {}
ShirsLazyTrixDB = { lootRows = 4 }

dofile(root .. "/ShirsLazyTrix_Loot.lua")

local function assertEqual(actual, expected, message)
  if actual ~= expected then error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

local function assertClose(actual, expected, message)
  if math.abs(actual - expected) > 0.000001 then
    error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

assertEqual(ShirsLazyTrix.NormalizeLootRows(3), 4, "loot row floor")
assertEqual(ShirsLazyTrix.NormalizeLootRows(13), 12, "loot row ceiling")
assertEqual(ShirsLazyTrix.NormalizeLootRows(7.6), 8, "loot row rounding")
assertEqual(ShirsLazyTrix.NormalizeLootRows("bad"), 4, "malformed loot rows")
assertEqual(ShirsLazyTrix.NormalizeLootRows(0 / 0), 4, "NaN loot rows")
assertEqual(ShirsLazyTrix.NormalizeLootRows(1 / 0), 4, "infinite loot rows repair")
assertEqual(ShirsLazyTrix.ApplyLootRows(8), true, "eight-row stock loot application")
assertEqual(LOOTFRAME_NUMBUTTONS, 8, "stock loot global row count")
assertEqual(LootFrame.height, 420, "stock loot frame expanded height")
assertClose(LootFrame.scale, 1, "expanded loot keeps stock header scale")
assertEqual(stockPanel.height, 239, "stock panel cropped before its original bottom border")
assertEqual(stockPanel.point[1], "TOPLEFT", "stock panel pinned to top-left")
assertEqual(itemsLabel.point[1], "CENTER", "Items label keeps stock center anchor")
assertEqual(itemsLabel.point[5], -26, "Items label stock top offset")
assertEqual(table.getn(LootFrame.shirsLazyTrixBodyStrips), 8, "bounded body strip pool")
assertEqual(LootFrame.shirsLazyTrixBodyStrips[1].height, 41, "body strip exact row height")
assertEqual(LootFrame.shirsLazyTrixBodyStrips[1].point[5], -239, "first body strip replaces original bottom border")
assertEqual(LootFrame.shirsLazyTrixBodyStrips[4].point[5], -362, "fourth body strip position")
assertEqual(LootFrame.shirsLazyTrixBodyStrips[5].shown, false, "unused body strip hidden")
assertEqual(LootFrame.shirsLazyTrixBottomStrip.height, 17, "bottom strip exact source height")
assertEqual(LootFrame.shirsLazyTrixBottomStrip.point[5], -403, "bottom strip moved below four added rows")
assertEqual(LootFrame.page, 2, "stock loot page clamped after row-count change")
assertEqual(ShirsLazyTrixDB.lootRows, 8, "stock loot row setting saved")
for index = 5, 8 do
  local button = named["LootButton" .. index]
  if not button then error("missing extra stock loot button " .. index, 2) end
  assertEqual(button.kind, "Button", "extra loot button frame type")
  assertEqual(button.template, "LootButtonTemplate", "extra loot button template")
  assertEqual(button.id, index, "extra loot button id")
  if type(button.SetSlot) ~= "function" then error("extra loot button missing SetSlot " .. index, 2) end
  assertEqual(button.point[1], "TOP", "extra loot button anchor")
  assertEqual(button.point[2], named["LootButton" .. (index - 1)], "extra loot button chain")
  assertEqual(button.point[3], "BOTTOM", "extra loot button relative anchor")
  assertEqual(button.point[5], -4, "extra loot button gap")
end
assertEqual(updateCalls, 1, "visible loot frame refresh after expansion")

assertEqual(ShirsLazyTrix.ApplyLootRows(4), true, "stock loot reset")
assertEqual(LOOTFRAME_NUMBUTTONS, 4, "stock loot row reset count")
assertEqual(LootFrame.height, 256, "stock loot frame reset height")
assertClose(LootFrame.scale, 1, "stock loot frame scale reset")
assertEqual(stockPanel.height, 256, "stock panel full height restored")
assertEqual(LootFrame.shirsLazyTrixBodyStrips[1].shown, false, "body strips hidden at four rows")
assertEqual(LootFrame.shirsLazyTrixBottomStrip.shown, false, "extra bottom strip hidden at four rows")
assertEqual(named.LootButton5.shown, false, "extra loot buttons hidden after reset")
assertEqual(ShirsLazyTrix.ApplyLootRows(12), true, "twelve-row stock loot application")
assertEqual(LootFrame.height, 584, "twelve-row stock loot frame height")
assertClose(LootFrame.scale, 1, "twelve-row loot keeps stock header scale")
assertEqual(LootFrame.shirsLazyTrixBodyStrips[8].point[5], -526, "eighth body strip position")
assertEqual(LootFrame.shirsLazyTrixBottomStrip.point[5], -567, "bottom strip reaches twelve-row bottom")

ShirsLazyTrixDB.expandLootRows = false
assertEqual(ShirsLazyTrix.ApplyLootRows(10), true, "disabled loot expansion keeps stock frame")
assertEqual(LOOTFRAME_NUMBUTTONS, 4, "disabled loot expansion uses stock row count")
assertEqual(LootFrame.height, 256, "disabled loot expansion restores stock height")
ShirsLazyTrixDB.expandLootRows = true
assertEqual(ShirsLazyTrix.ApplyLootRows(10), true, "re-enabled loot expansion")
assertEqual(LOOTFRAME_NUMBUTTONS, 10, "re-enabled loot expansion restores row count")

pfUI = { loot = {} }
assertEqual(ShirsLazyTrix.ApplyLootRows(10), false, "pfUI-owned loot must not be changed")
assertEqual(LOOTFRAME_NUMBUTTONS, 10, "pfUI guard preserves stock row count")
assertEqual(ShirsLazyTrixDB.lootRows, 10, "pfUI guard still saves the chosen stock row count")

print("stock-loot-row-expansion: PASS")
