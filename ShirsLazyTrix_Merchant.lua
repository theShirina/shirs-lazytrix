-- Shir's LazyTrix gray-only merchant automation.
-- Queue and settlement behavior adapted from Shir's Inventory v0.5.3 (MIT).

local graySaleState

local function merchantCanSell()
  return MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab ~= 2
end

local function itemIdFromLink(link)
  if type(link) ~= "string" then return nil end
  local _, _, rawItemId = string.find(link, "item:(%d+)")
  return tonumber(rawItemId)
end

local function resolveQuality(itemId, link, containerQuality)
  if type(containerQuality) == "number" and containerQuality >= 0 then
    return containerQuality
  end
  if type(GetItemInfo) ~= "function" then
    return containerQuality
  end

  local query = itemId or link
  if query == nil then
    return containerQuality
  end
  local _, _, itemQuality = GetItemInfo(query)
  if type(itemQuality) == "number" and itemQuality >= 0 then
    return itemQuality
  end
  return containerQuality
end

local function collectGrayItems()
  local queue = {}
  local bag
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag) or 0
    local slot
    for slot = 1, slots do
      local texture, _, locked, quality = GetContainerItemInfo(bag, slot)
      if texture and not locked then
        local link = GetContainerItemLink(bag, slot)
        local itemId = itemIdFromLink(link)
        quality = resolveQuality(itemId, link, quality)
        if itemId and quality == 0 then
          table.insert(queue, {
            bag = bag,
            slot = slot,
            itemId = itemId,
          })
        end
      end
    end
  end
  return queue
end

local function formatMoney(copper)
  local sign = ""
  if copper < 0 then
    sign = "-"
    copper = -copper
  end

  local gold = math.floor(copper / 10000)
  local silver = math.floor(math.mod(copper, 10000) / 100)
  local remainder = math.mod(copper, 100)
  local parts = {}
  if gold > 0 then table.insert(parts, gold .. "g") end
  if silver > 0 then table.insert(parts, silver .. "s") end
  if remainder > 0 or table.getn(parts) == 0 then table.insert(parts, remainder .. "c") end
  return sign .. table.concat(parts, " ")
end

function ShirsLazyTrix.StartAutoGraySale()
  if type(ShirsLazyTrixDB) ~= "table" or not ShirsLazyTrixDB.autoSellGray then
    graySaleState = nil
    return 0, "disabled"
  end
  if not merchantCanSell() then
    graySaleState = nil
    return 0, "merchant"
  end

  local queue = collectGrayItems()
  if table.getn(queue) == 0 then
    graySaleState = nil
    return 0, "empty"
  end

  graySaleState = {
    queue = queue,
    index = 1,
    sold = 0,
    startMoney = type(GetMoney) == "function" and GetMoney() or 0,
  }
  return table.getn(queue), "started"
end

function ShirsLazyTrix.CancelGraySale()
  graySaleState = nil
end

function ShirsLazyTrix.GetGraySaleState()
  return graySaleState
end

function ShirsLazyTrix.SellNextGray()
  if not graySaleState then
    return false, "idle"
  end
  if type(ShirsLazyTrixDB) ~= "table" or not ShirsLazyTrixDB.autoSellGray then
    graySaleState = nil
    return false, "disabled"
  end
  if not merchantCanSell() then
    graySaleState = nil
    return false, "cancelled"
  end

  local entry = graySaleState.queue[graySaleState.index]
  if not entry then
    local currentMoney = type(GetMoney) == "function" and GetMoney() or graySaleState.startMoney
    if graySaleState.summaryMoney == nil then
      graySaleState.summaryMoney = currentMoney
      graySaleState.summaryChecks = 1
      graySaleState.summaryStableChecks = 1
      return false, "waiting"
    end

    graySaleState.summaryChecks = graySaleState.summaryChecks + 1
    if currentMoney == graySaleState.summaryMoney then
      graySaleState.summaryStableChecks = graySaleState.summaryStableChecks + 1
    else
      graySaleState.summaryMoney = currentMoney
      graySaleState.summaryStableChecks = 0
    end

    local gained = currentMoney - graySaleState.startMoney
    if not (gained ~= 0 and graySaleState.summaryStableChecks >= 2) and graySaleState.summaryChecks < 12 then
      return false, "waiting"
    end

    local sold = graySaleState.sold
    graySaleState = nil
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cff68ccefShir's LazyTrix:|r sold " .. sold .. " gray stack(s) for " .. formatMoney(gained) .. ".")
    end
    return false, "complete"
  end
  graySaleState.index = graySaleState.index + 1

  local texture, _, locked, quality = GetContainerItemInfo(entry.bag, entry.slot)
  local link = GetContainerItemLink(entry.bag, entry.slot)
  local itemId = itemIdFromLink(link)
  quality = resolveQuality(itemId, link, quality)
  if not texture or locked or itemId ~= entry.itemId or quality ~= 0 then
    return false, "skipped"
  end

  UseContainerItem(entry.bag, entry.slot)
  graySaleState.sold = graySaleState.sold + 1
  return true, "sold"
end
