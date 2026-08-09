-- Shir's LazyTrix gray-only merchant automation tests for Lua 5.0.3

local root = arg and arg[1] or "."
local merchantPath = root .. "/ShirsLazyTrix_Merchant.lua"

ShirsLazyTrix = {}
ShirsLazyTrixDB = {
  autoSellGray = false,
  junkItems = { [7076] = true },
}

local merchantOpen = true
MerchantFrame = {
  selectedTab = 1,
  IsShown = function() return merchantOpen end,
}

local money = 10000
function GetMoney() return money end

function GetContainerNumSlots(bag)
  if bag == 0 then return 4 end
  if bag == 1 then return 2 end
  return 0
end

local items = {
  ["0:1"] = { texture = "fallback-gray", count = 2, locked = nil, quality = -1, link = "|Hitem:111:0:0:0|h[Cracked Bill]|h" },
  ["0:2"] = { texture = "marked-rare", count = 1, locked = nil, quality = 2, link = "|Hitem:7076:0:0:0|h[Essence of Earth]|h" },
  ["0:3"] = { texture = "white", count = 1, locked = nil, quality = -1, link = "|Hitem:333:0:0:0|h[Keep]|h" },
  ["0:4"] = { texture = "missing-link", count = 1, locked = nil, quality = 0, link = nil },
  ["1:1"] = { texture = "locked-gray", count = 1, locked = 1, quality = 0, link = "|Hitem:444:0:0:0|h[Locked Gray]|h" },
  ["1:2"] = { texture = "direct-gray", count = 1, locked = nil, quality = 0, link = "|Hitem:555:0:0:0|h[Gray Stack]|h" },
}
local itemQualities = { [111] = 0, [333] = 1, [444] = 0, [555] = 0, [7076] = 2 }

function GetItemInfo(value)
  assert(value ~= nil, "GetItemInfo must not receive nil")
  local itemId = tonumber(value)
  if not itemId and type(value) == "string" then
    local _, _, rawItemId = string.find(value, "item:(%d+)")
    itemId = tonumber(rawItemId)
  end
  return "Item", value, itemQualities[itemId]
end

function GetContainerItemInfo(bag, slot)
  local item = items[bag .. ":" .. slot]
  if not item then return nil end
  return item.texture, item.count, item.locked, item.quality
end

function GetContainerItemLink(bag, slot)
  local item = items[bag .. ":" .. slot]
  return item and item.link
end

local sold = {}
function UseContainerItem(bag, slot)
  table.insert(sold, bag .. ":" .. slot)
end

local messages = {}
DEFAULT_CHAT_FRAME = {
  AddMessage = function(_, text) table.insert(messages, text) end,
}

assert(loadfile(merchantPath))()

local count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 0 and status == "disabled", "auto-sell must default to opt-in")

ShirsLazyTrixDB.autoSellGray = true
count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "only unlocked gray stacks with stable identities should queue")

ShirsLazyTrixDB.autoSellGray = false
local acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "disabled", "turning auto-sell off must cancel an active queue")
assert(table.getn(sold) == 0, "disabled master switch allowed a queued sale")
ShirsLazyTrixDB.autoSellGray = true
count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "gray sale should restart after re-enabling")

acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(acted and tickStatus == "sold", "first driver tick should sell one gray stack")
assert(table.getn(sold) == 1 and sold[1] == "0:1", "fallback quality gray should sell first")

items["1:2"].quality = 1
itemQualities[555] = 1
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "skipped", "slot quality must be revalidated before sale")
assert(table.getn(sold) == 1, "white, rare, marked, unresolved, locked, or changed items must not sell")

acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "waiting", "summary must wait for delayed merchant money")
assert(table.getn(messages) == 0, "summary printed before proceeds settled")
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "waiting", "summary must remain active while money is stale")

money = 12868
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "waiting", "summary must observe the money change before settling")
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "waiting", "summary needs a stable post-sale observation")
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "complete", "summary should finish after stable proceeds")
assert(table.getn(messages) == 1 and string.find(messages[1], "sold 1 gray stack(s) for 28s 68c.", 1, true),
  "summary should report the sold count and formatted settled proceeds")

items["1:2"].quality = 0
itemQualities[555] = 0
count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "zero-change timeout sale should start")
assert(ShirsLazyTrix.SellNextGray() == true, "first zero-change stack should submit")
assert(ShirsLazyTrix.SellNextGray() == true, "second zero-change stack should submit")
local check
for check = 1, 11 do
  acted, tickStatus = ShirsLazyTrix.SellNextGray()
  assert(not acted and tickStatus == "waiting", "zero-change summary ended before its bound")
end
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "complete", "zero-change summary must stop on its twelfth check")
assert(table.getn(messages) == 2 and string.find(messages[2], "0c.", 1, true),
  "zero-change timeout should report formatted zero proceeds")

count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "new sale should be startable")
merchantOpen = false
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "cancelled", "merchant close must cancel before another submission")

merchantOpen = true
MerchantFrame.selectedTab = 1
count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "active-buyback cancellation sale should start")
MerchantFrame.selectedTab = 2
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "cancelled", "switching to buyback must cancel an active queue")
assert(table.getn(sold) == 3, "buyback switch allowed another sale")

MerchantFrame.selectedTab = 1
count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "identity revalidation sale should start")
local originalLink = items["0:1"].link
items["0:1"].link = "|Hitem:999:0:0:0|h[Replacement Gray]|h"
itemQualities[999] = 0
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "skipped", "changed slot identity must be skipped")
assert(table.getn(sold) == 3, "changed slot identity was sold")
ShirsLazyTrix.CancelGraySale()
items["0:1"].link = originalLink

count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 2 and status == "started", "lock revalidation sale should start")
items["0:1"].locked = 1
acted, tickStatus = ShirsLazyTrix.SellNextGray()
assert(not acted and tickStatus == "skipped", "newly locked slot must be skipped")
assert(table.getn(sold) == 3, "newly locked slot was sold")
ShirsLazyTrix.CancelGraySale()
items["0:1"].locked = nil

MerchantFrame.selectedTab = 2
count, status = ShirsLazyTrix.StartAutoGraySale()
assert(count == 0 and status == "merchant", "buyback tab must block automatic selling")

ShirsLazyTrix.CancelGraySale()
assert(ShirsLazyTrix.GetGraySaleState() == nil, "cancel must clear all sale state")
assert(table.getn(sold) == 3, "gray-only policy sold an unexpected stack")

print("MERCHANT_GRAY_ONLY_QUEUE_TEST=PASS")
