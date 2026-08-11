-- Item-ID tooltip tests for Lua 5.0.3.

local root = arg and arg[1] or "."
local named = {}
local links = {}
local originals = {}


local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local function pack(...)
  return arg
end

local function makeLine(text)
  local line = { text = text }
  function line:GetText() return self.text end
  return line
end

local tooltip = { name = "GameTooltip", lines = {}, calls = {} }
function tooltip:GetName() return self.name end
function tooltip:NumLines() return table.getn(self.lines) end
function tooltip:AddLine(text, r, g, b)
  table.insert(self.lines, { text = text, color = { r, g, b } })
  named[self.name .. "TextLeft" .. table.getn(self.lines)] = makeLine(text)
end
function tooltip:Show() self.shows = (self.shows or 0) + 1 end


local methods = {
  "SetHyperlink", "SetBagItem", "SetInventoryItem", "SetLootItem",
  "SetMerchantItem", "SetQuestItem", "SetQuestLogItem",
  "SetTradeSkillItem", "SetCraftItem",
}
local i
for i = 1, table.getn(methods) do
  local method = methods[i]
  originals[method] = function(self, a, b, c, d, e, f)
    self.calls[method] = (self.calls[method] or 0) + 1
    self.lastArguments = { a, b, c, d, e, f }
    self.lines = {}
    local lineIndex
    for lineIndex = 1, 20 do named[self.name .. "TextLeft" .. lineIndex] = nil end
    if links.existingLine then self:AddLine(links.existingLine, 1, 1, 1) end

    if links.nilReturns then return "one", nil, "three", nil end
    return method .. "-one", method .. "-two", method .. "-three", method .. "-four", method .. "-five", method .. "-six"
  end
  tooltip[method] = originals[method]
end

GameTooltip = tooltip
ItemRefTooltip = { name = "ItemRefTooltip", lines = {}, calls = {} }
function ItemRefTooltip:GetName() return self.name end
function ItemRefTooltip:NumLines() return table.getn(self.lines) end
function ItemRefTooltip:AddLine(text, r, g, b)
  table.insert(self.lines, { text = text, color = { r, g, b } })
  named[self.name .. "TextLeft" .. table.getn(self.lines)] = makeLine(text)
end
function ItemRefTooltip:Show() self.shows = (self.shows or 0) + 1 end
function ItemRefTooltip:SetHyperlink(link)
  self.calls.SetHyperlink = (self.calls.SetHyperlink or 0) + 1
  self.lines = {}
  return "itemref-one", "itemref-two"
end
function getglobal(name) return named[name] end
function GetContainerItemLink(bag, slot) return links.bag end
function GetInventoryItemLink(unit, slot) return links.inventory end
function GetLootSlotLink(slot) return links.loot end
function GetMerchantItemLink(slot) return links.merchant end
function GetQuestItemLink(kind, slot) return links.quest end
function GetQuestLogItemLink(kind, slot) return links.questLog end
function GetTradeSkillItemLink(skill) return links.tradeItem end
function GetTradeSkillReagentItemLink(skill, reagent) return links.tradeReagent end
function GetCraftItemLink(skill) return links.craftItem end
function GetCraftReagentItemLink(skill, reagent) return links.craftReagent end

ShirsLazyTrix = {}
ShirsLazyTrixDB = { showItemIDs = false }
dofile(root .. "/ShirsLazyTrix_Tooltips.lua")

assertEqual(ShirsLazyTrix.ExtractItemID("|cff1eff00|Hitem:19019:0:0:0|h[Thunderfury]|h|r"), 19019, "colored item link")
assertEqual(ShirsLazyTrix.ExtractItemID("item:6948:0:0:0"), 6948, "raw item hyperlink")
assertEqual(ShirsLazyTrix.ExtractItemID("item:6948:0:-12:34"), 6948, "signed Vanilla item fields")
assertEqual(ShirsLazyTrix.ExtractItemID("spell:6948"), nil, "spell link rejected")
assertEqual(ShirsLazyTrix.ExtractItemID("item:0:0:0:0"), nil, "zero item ID rejected")
assertEqual(ShirsLazyTrix.ExtractItemID("item:2147483648:0:0:0"), nil, "oversized item ID rejected")
assertEqual(ShirsLazyTrix.ExtractItemID({}), nil, "non-string link rejected")
local malformed = {
  "item:12oops",
  "item:12.5:0:0:0",
  "prefix|Hitem:13oops|h[x]|h",
  "|Hitem:14x:0:0:0|h[x]|h",
  "|Hitem:15|h[x]|h",
  "unrelated|Hitem:321:0:0:0|h[x]|h",
  "|Hitem:321:0:0:0",
  "item:12::::",
  "item:12:---",
  "item:12::0:0",
  "|Hitem:12::::|h[x]|h",
  "|cffffffff|Hitem:12:---|h[x]|h|r",
}
for i = 1, table.getn(malformed) do
  assertEqual(ShirsLazyTrix.ExtractItemID(malformed[i]), nil, "malformed item link rejected " .. i)
end

ShirsLazyTrix.InstallItemIDTooltipHooks()
ShirsLazyTrix.InstallItemIDTooltipHooks()
links.bag = "|Hitem:12345:0:0:0|h[Test]|h"
local one, two = tooltip:SetBagItem(2, 7)
assertEqual(one, "SetBagItem-one", "first original return preserved")
assertEqual(two, "SetBagItem-two", "second original return preserved")
assertEqual(tooltip.calls.SetBagItem, 1, "hook installation is idempotent")
assertEqual(tooltip:NumLines(), 0, "disabled setting adds no line")

ShirsLazyTrixDB.showItemIDs = true
one, two = tooltip:SetBagItem(2, 7)
assertEqual(tooltip:NumLines(), 1, "enabled bag tooltip adds one line")
assertEqual(tooltip.lines[1].text, "Item ID: 12345", "bag item ID text")
assertEqual(tooltip.lines[1].color[1], 0.8, "item ID line red channel")
assertEqual(tooltip.lines[1].color[2], 0.5, "item ID line green channel")
assertEqual(tooltip.lines[1].color[3], 0.6, "item ID line blue channel")
assertEqual(one, "SetBagItem-one", "hook keeps original first return when enabled")
assertEqual(two, "SetBagItem-two", "hook keeps original second return when enabled")

local r1, r2, r3, r4, r5, r6 = tooltip:SetHyperlink("item:3333:0:0:0", 2, 3, 4, 5, 6)
assertEqual(tooltip.lastArguments[5], 5, "fifth wrapped argument preserved")
assertEqual(tooltip.lastArguments[6], 6, "sixth wrapped argument preserved")
assertEqual(r1, "SetHyperlink-one", "first of six returns preserved")
assertEqual(r6, "SetHyperlink-six", "sixth wrapped return preserved")

links.nilReturns = true
local nilResults = pack(tooltip:SetHyperlink("item:3333:0:0:0"))
assertEqual(nilResults.n, 4, "nil-bearing return count preserved")
assertEqual(nilResults[1], "one", "nil-bearing first return preserved")
assertEqual(nilResults[2], nil, "nil-bearing second return preserved")
assertEqual(nilResults[3], "three", "return after interior nil preserved")
assertEqual(nilResults[4], nil, "trailing nil return preserved")
links.nilReturns = false

ItemRefTooltip:SetHyperlink("item:4444:0:0:0")
assertEqual(ItemRefTooltip.lines[1].text, "Item ID: 4444", "clicked item-link tooltip is covered")

local cases = {
  { method = "SetHyperlink", key = nil, link = "item:1001:0:0:0", args = { "item:1001:0:0:0" } },
  { method = "SetInventoryItem", key = "inventory", link = "|Hitem:1002:0:0:0|h[x]|h", args = { "player", 16 } },
  { method = "SetLootItem", key = "loot", link = "|Hitem:1003:0:0:0|h[x]|h", args = { 1 } },
  { method = "SetMerchantItem", key = "merchant", link = "|Hitem:1004:0:0:0|h[x]|h", args = { 1 } },
  { method = "SetQuestItem", key = "quest", link = "|Hitem:1005:0:0:0|h[x]|h", args = { "reward", 1 } },
  { method = "SetQuestLogItem", key = "questLog", link = "|Hitem:1006:0:0:0|h[x]|h", args = { "reward", 1 } },
  { method = "SetTradeSkillItem", key = "tradeItem", link = "|Hitem:1007:0:0:0|h[x]|h", args = { 3 } },
  { method = "SetCraftItem", key = "craftItem", link = "|Hitem:1008:0:0:0|h[x]|h", args = { 3 } },
  { method = "SetTradeSkillItem", key = "tradeReagent", link = "|Hitem:1009:0:0:0|h[x]|h", args = { 3, 2 } },
  { method = "SetCraftItem", key = "craftReagent", link = "|Hitem:1010:0:0:0|h[x]|h", args = { 3, 2 } },
}
for i = 1, table.getn(cases) do
  local case = cases[i]
  if case.key then links[case.key] = case.link end
  tooltip[case.method](tooltip, unpack(case.args))
  assertEqual(tooltip.lines[table.getn(tooltip.lines)].text, "Item ID: " .. tostring(1000 + i), case.method .. " item ID")
end

links.existingLine = "Item ID: 12345"
tooltip:SetBagItem(2, 7)
assertEqual(tooltip:NumLines(), 1, "existing matching item-ID line is not duplicated")
links.existingLine = nil

links.bag = "|Hspell:12345|h[Test]|h"
tooltip:SetBagItem(2, 7)
assertEqual(tooltip:NumLines(), 0, "non-item link adds no line")

InformantConfig = { filters = { ["show-id"] = "on" } }
tooltip:SetHyperlink("item:2222:0:0:0")
assertEqual(tooltip:NumLines(), 0, "active Informant item-ID line is not duplicated")
InformantConfig.filters["all"] = "off"
tooltip:SetHyperlink("item:2222:0:0:0")
assertEqual(tooltip.lines[1].text, "Item ID: 2222", "globally disabled Informant does not suppress LazyTrix")
InformantConfig.filters["all"] = "on"
InformantConfig.filters["show-id"] = "off"
tooltip:SetHyperlink("item:2222:0:0:0")
assertEqual(tooltip.lines[1].text, "Item ID: 2222", "LazyTrix shows its line when Informant item IDs are off")

local late = { name = "LateItemRefTooltip", lines = {} }
function late:GetName() return self.name end
function late:NumLines() return table.getn(self.lines) end
function late:AddLine(text) table.insert(self.lines, { text = text }); named[self.name .. "TextLeft" .. table.getn(self.lines)] = makeLine(text) end
function late:Show() end
ItemRefTooltip = late
ShirsLazyTrix.InstallItemIDTooltipHooks()
function late:SetHyperlink(link) self.lines = {}; return "late" end
ShirsLazyTrix.InstallItemIDTooltipHooks()
late:SetHyperlink("item:5555:0:0:0")
assertEqual(late.lines[1].text, "Item ID: 5555", "method restored after initial hook setup is wrapped later")

print("item-id-tooltips: PASS")
