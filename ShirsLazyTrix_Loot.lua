ShirsLazyTrix = ShirsLazyTrix or {}

local STOCK_LOOT_ROWS = 4
local MAX_LOOT_ROWS = 12
local STOCK_LOOT_HEIGHT = 256
local LOOT_ROW_STRIDE = 41
local LOOT_BODY_START = 239
local LOOT_BOTTOM_HEIGHT = 17
local LOOT_BODY_SOURCE_TOP = 180 / 256
local LOOT_BODY_SOURCE_BOTTOM = 221 / 256
local LOOT_BOTTOM_SOURCE_TOP = 239 / 256
local extraLootButtons = {}
local stockPanelTexture = nil
local itemsLabel = nil

local function pfUIOwnsLoot()
  return type(pfUI) == "table" and type(pfUI.loot) == "table"
end

function ShirsLazyTrix.NormalizeLootRows(value)
  value = tonumber(value)
  local text = value and string.lower(tostring(value)) or ""
  if not value or string.find(text, "nan", 1, true) or string.find(text, "inf", 1, true) or
     string.find(text, "#", 1, true) then return STOCK_LOOT_ROWS end
  value = math.floor(value + 0.5)
  if value < STOCK_LOOT_ROWS then value = STOCK_LOOT_ROWS end
  if value > MAX_LOOT_ROWS then value = MAX_LOOT_ROWS end
  return value
end

local function normalizeLootPage(rows)
  if not LootFrame then return end
  local items = nil
  if type(GetNumLootItems) == "function" then items = tonumber(GetNumLootItems()) end
  if not items then items = tonumber(LootFrame.numLootItems) end
  if not items or items ~= items or items < 0 or items > 1000 then items = 0 end
  items = math.floor(items)
  LootFrame.numLootItems = items
  local perPage = rows
  if items > rows then perPage = rows - 1 end
  if perPage < 1 then perPage = 1 end
  local maxPage = math.max(1, math.ceil(items / perPage))
  local page = tonumber(LootFrame.page)
  if not page or page ~= page then page = 1 end
  page = math.floor(page)
  if page < 1 then page = 1 end
  if page > maxPage then page = maxPage end
  LootFrame.page = page
end

function ShirsLazyTrix.GetLootRows()
  if type(ShirsLazyTrixDB) ~= "table" then return STOCK_LOOT_ROWS end
  return ShirsLazyTrix.NormalizeLootRows(ShirsLazyTrixDB.lootRows)
end

function ShirsLazyTrix.IsLootRowsExpansionEnabled()
  return type(ShirsLazyTrixDB) ~= "table" or ShirsLazyTrixDB.expandLootRows ~= false
end

local function ensureLootButton(index)
  local name = "LootButton" .. index
  local button = type(getglobal) == "function" and getglobal(name) or nil
  if button then
    if not button.SetSlot and type(button.SetID) == "function" then
      button.SetSlot = button.SetID
    end
    return button
  end
  if type(CreateFrame) ~= "function" or not LootFrame then return nil end
  -- Stock rows are native LootButton widgets; ordinary Buttons never receive
  -- native loot pickup, so extra rows must be created as LootButton too.
  button = nil
  local ok, created = pcall(CreateFrame, "LootButton", name, LootFrame, "LootButtonTemplate")
  if ok then button = created end
  if not button then
    ok, created = pcall(CreateFrame, "Button", name, LootFrame, "LootButtonTemplate")
    if ok then button = created end
  end
  if not button then return nil end
  if type(button.SetID) == "function" then
    button:SetID(index)
  end
  if not button.SetSlot and type(button.SetID) == "function" then
    button.SetSlot = button.SetID
  end
  if type(button.RegisterForClicks) == "function" then
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end
  if type(button.EnableMouse) == "function" then
    button:EnableMouse(true)
  end
  if type(button.SetFrameLevel) == "function" and type(LootFrame.GetFrameLevel) == "function" then
    button:SetFrameLevel(LootFrame:GetFrameLevel() + 4)
  end
  extraLootButtons[index] = button
  return button
end

local function positionLootButtons(rows)
  local index
  for index = STOCK_LOOT_ROWS + 1, MAX_LOOT_ROWS do
    local button = ensureLootButton(index)
    if not button then return false end
    button:ClearAllPoints()
    button:SetPoint("TOP", getglobal("LootButton" .. (index - 1)), "BOTTOM", 0, -4)
    if index > rows then button:Hide() end
  end
  return true
end

local function regionObjectType(region)
  if not region or type(region.GetObjectType) ~= "function" then return nil end
  local ok, value = pcall(function() return region:GetObjectType() end)
  if not ok then return nil end
  return value
end

local function findStockLootRegions()
  if (stockPanelTexture and itemsLabel) or not LootFrame or type(LootFrame.GetRegions) ~= "function" then return end
  local regions = { LootFrame:GetRegions() }
  local index
  for index = 1, table.getn(regions) do
    local region = regions[index]
    local objectType = regionObjectType(region)
    if not stockPanelTexture and objectType == "Texture" and type(region.GetTexture) == "function" then
      local texture = region:GetTexture()
      if type(texture) == "string" and string.find(string.lower(texture), "ui-lootpanel", 1, true) then
        stockPanelTexture = region
      end
    elseif not itemsLabel and objectType == "FontString" and type(region.GetText) == "function" then
      local text = region:GetText()
      if text == ITEMS or text == "Items" then itemsLabel = region end
    end
  end
end

local function ensureLootExtension()
  if not LootFrame or type(LootFrame.CreateTexture) ~= "function" then return false end
  if not LootFrame.shirsLazyTrixBodyStrips then
    LootFrame.shirsLazyTrixBodyStrips = {}
    local index
    for index = 1, MAX_LOOT_ROWS - STOCK_LOOT_ROWS do
      local strip = LootFrame:CreateTexture("ShirsLazyTrixLootBody" .. index, "BORDER")
      strip:SetTexture("Interface\\LootFrame\\UI-LootPanel")
      table.insert(LootFrame.shirsLazyTrixBodyStrips, strip)
    end
  end
  if not LootFrame.shirsLazyTrixBottomStrip then
    LootFrame.shirsLazyTrixBottomStrip = LootFrame:CreateTexture("ShirsLazyTrixLootBottom", "BORDER")
    LootFrame.shirsLazyTrixBottomStrip:SetTexture("Interface\\LootFrame\\UI-LootPanel")
  end
  return true
end

local function applyLootArtwork(rows)
  local extraRows = rows - STOCK_LOOT_ROWS
  local extraHeight = extraRows * LOOT_ROW_STRIDE
  if LootFrame.SetScale then LootFrame:SetScale(1) end
  if LootFrame.SetHeight then LootFrame:SetHeight(STOCK_LOOT_HEIGHT + extraHeight) end
  findStockLootRegions()
  if stockPanelTexture then
    stockPanelTexture:ClearAllPoints()
    stockPanelTexture:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", 0, 0)
    stockPanelTexture:SetWidth(STOCK_LOOT_HEIGHT)
    if extraRows > 0 then
      stockPanelTexture:SetHeight(LOOT_BODY_START)
      stockPanelTexture:SetTexCoord(0, 1, 0, LOOT_BODY_START / STOCK_LOOT_HEIGHT)
    else
      stockPanelTexture:SetHeight(STOCK_LOOT_HEIGHT)
      stockPanelTexture:SetTexCoord(0, 1, 0, 1)
    end
  end
  if itemsLabel then
    itemsLabel:ClearAllPoints()
    itemsLabel:SetPoint("CENTER", LootFrame, "TOP", -12, -26)
  end
  if not ensureLootExtension() then return end
  local index
  for index = 1, MAX_LOOT_ROWS - STOCK_LOOT_ROWS do
    local strip = LootFrame.shirsLazyTrixBodyStrips[index]
    if index <= extraRows then
      strip:ClearAllPoints()
      strip:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", 0, -(LOOT_BODY_START + (index - 1) * LOOT_ROW_STRIDE))
      strip:SetWidth(STOCK_LOOT_HEIGHT)
      strip:SetHeight(LOOT_ROW_STRIDE)
      strip:SetTexCoord(0, 1, LOOT_BODY_SOURCE_TOP, LOOT_BODY_SOURCE_BOTTOM)
      strip:Show()
    else
      strip:Hide()
    end
  end
  local bottom = LootFrame.shirsLazyTrixBottomStrip
  if extraRows > 0 then
    bottom:ClearAllPoints()
    bottom:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", 0, -(LOOT_BODY_START + extraHeight))
    bottom:SetWidth(STOCK_LOOT_HEIGHT)
    bottom:SetHeight(LOOT_BOTTOM_HEIGHT)
    bottom:SetTexCoord(0, 1, LOOT_BOTTOM_SOURCE_TOP, 1)
    bottom:Show()
  else
    bottom:Hide()
  end
end

function ShirsLazyTrix.ApplyLootRows(value)
  local rows = ShirsLazyTrix.NormalizeLootRows(value)
  if type(ShirsLazyTrixDB) ~= "table" then ShirsLazyTrixDB = {} end
  ShirsLazyTrixDB.lootRows = rows
  if not ShirsLazyTrix.IsLootRowsExpansionEnabled() then rows = STOCK_LOOT_ROWS end
  if pfUIOwnsLoot() or not LootFrame then return false end
  if not positionLootButtons(rows) then return false end
  LOOTFRAME_NUMBUTTONS = rows
  applyLootArtwork(rows)
  normalizeLootPage(rows)
  local visible = (LootFrame.IsShown and LootFrame:IsShown()) or
    (LootFrame.IsVisible and LootFrame:IsVisible())
  if visible and type(LootFrame_Update) == "function" then LootFrame_Update() end
  return true
end

function ShirsLazyTrix.RefreshLootRows()
  return ShirsLazyTrix.ApplyLootRows(ShirsLazyTrix.GetLootRows())
end
