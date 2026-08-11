local MAX_ITEM_ID = 2147483647
local ITEM_ID_RED = 0.8
local ITEM_ID_GREEN = 0.5
local ITEM_ID_BLUE = 0.6
local installedMethods = {}

local function packReturns(...)
  return arg
end

local function informantShowsItemID()
  if type(InformantConfig) ~= "table" or type(InformantConfig.filters) ~= "table" then
    return false
  end
  local master = InformantConfig.filters["all"]
  if master == false or master == "off" then return false end
  local value = InformantConfig.filters["show-id"]
  return value == true or value == "on"
end

function ShirsLazyTrix.ExtractItemID(link)
  if type(link) ~= "string" then return nil end

  local _, _, text = string.find(link, "^item:(%d+):%-?%d+:%-?%d+:%-?%d+$")
  if not text then
    _, _, text = string.find(link, "^|Hitem:(%d+):%-?%d+:%-?%d+:%-?%d+|h%[.*%]|h$")
  end
  if not text then
    _, _, text = string.find(link, "^|c%x%x%x%x%x%x%x%x|Hitem:(%d+):%-?%d+:%-?%d+:%-?%d+|h%[.*%]|h|r$")
  end
  if not text then return nil end

  local itemID = tonumber(text)
  if not itemID or itemID < 1 or itemID > MAX_ITEM_ID or math.floor(itemID) ~= itemID then
    return nil
  end
  return itemID
end

local function existingItemIDLine(tooltip, expected)
  if type(tooltip.GetName) ~= "function" or type(tooltip.NumLines) ~= "function" or type(getglobal) ~= "function" then
    return false
  end

  local okName, name = pcall(tooltip.GetName, tooltip)
  local okCount, count = pcall(tooltip.NumLines, tooltip)
  if not okName or not okCount or type(name) ~= "string" or type(count) ~= "number" then
    return false
  end

  local i
  for i = 1, count do
    local line = getglobal(name .. "TextLeft" .. i)
    if line and type(line.GetText) == "function" then
      local okText, text = pcall(line.GetText, line)
      if okText and text == expected then return true end
    end
  end
  return false
end

function ShirsLazyTrix.AddItemIDToTooltip(tooltip, link)
  if type(ShirsLazyTrixDB) ~= "table" or ShirsLazyTrixDB.showItemIDs ~= true then return end
  if informantShowsItemID() then return end
  if type(tooltip) ~= "table" and type(tooltip) ~= "userdata" then return end
  if type(tooltip.AddLine) ~= "function" then return end

  local itemID = ShirsLazyTrix.ExtractItemID(link)
  if not itemID then return end

  local text = "Item ID: " .. tostring(itemID)
  if existingItemIDLine(tooltip, text) then return end

  tooltip:AddLine(text, ITEM_ID_RED, ITEM_ID_GREEN, ITEM_ID_BLUE)
  if type(tooltip.Show) == "function" then tooltip:Show() end
end

local function safeLink(func, first, second)
  if type(func) ~= "function" then return nil end
  local ok, link = pcall(func, first, second)
  if not ok or type(link) ~= "string" then return nil end
  return link
end

local function installMethod(tooltip, name, linkReader)
  local tooltipMethods = installedMethods[tooltip]
  if not tooltipMethods then
    tooltipMethods = {}
    installedMethods[tooltip] = tooltipMethods
  end
  if tooltipMethods[name] then return end

  local original = tooltip[name]
  if type(original) ~= "function" then return end

  local wrapper = function(self, ...)
    local arguments = arg
    local results = packReturns(original(self, unpack(arguments)))
    local link = linkReader(unpack(arguments))
    ShirsLazyTrix.AddItemIDToTooltip(self, link)
    return unpack(results)
  end
  tooltipMethods[name] = wrapper
  tooltip[name] = wrapper
end

local function installTooltipHooks(tooltip)
  if not tooltip then return end
  installMethod(tooltip, "SetHyperlink", function(link) return link end)
  installMethod(tooltip, "SetBagItem", function(bag, slot)
    return safeLink(GetContainerItemLink, bag, slot)
  end)
  installMethod(tooltip, "SetInventoryItem", function(unit, slot)
    return safeLink(GetInventoryItemLink, unit, slot)
  end)
  installMethod(tooltip, "SetLootItem", function(slot)
    return safeLink(GetLootSlotLink, slot)
  end)
  installMethod(tooltip, "SetMerchantItem", function(slot)
    return safeLink(GetMerchantItemLink, slot)
  end)
  installMethod(tooltip, "SetQuestItem", function(kind, slot)
    return safeLink(GetQuestItemLink, kind, slot)
  end)
  installMethod(tooltip, "SetQuestLogItem", function(kind, slot)
    return safeLink(GetQuestLogItemLink, kind, slot)
  end)
  installMethod(tooltip, "SetTradeSkillItem", function(skill, reagent)
    if reagent ~= nil then return safeLink(GetTradeSkillReagentItemLink, skill, reagent) end
    return safeLink(GetTradeSkillItemLink, skill)
  end)
  installMethod(tooltip, "SetCraftItem", function(skill, reagent)
    if reagent ~= nil then return safeLink(GetCraftReagentItemLink, skill, reagent) end
    return safeLink(GetCraftItemLink, skill)
  end)
end

function ShirsLazyTrix.InstallItemIDTooltipHooks()
  installTooltipHooks(GameTooltip)
  if ItemRefTooltip ~= GameTooltip then installTooltipHooks(ItemRefTooltip) end
end

ShirsLazyTrix.InstallItemIDTooltipHooks()
