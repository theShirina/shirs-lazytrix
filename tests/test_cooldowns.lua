-- Profession cooldown tracking and one-click craft tests for Lua 5.0.3.

local root = arg and arg[1] or "."
local now = 200000
local uptime = 500
local profession = "Tailoring"
local tradeRows = {}
local bagRows = {}
local raidRows = {}
local raidInfoRequests = 0
local castCalls = {}
local craftCalls = {}
local itemUseCalls = {}
local chat = {}
local merchantOpen = false
local cursorHasItem = false
local characterName = "Shirina"
local unsafeWindows = {
  merchant = false,
  bank = false,
  trade = false,
  auction = false,
  mail = false,
}

function time() return now end
function GetTime() return uptime end
function UnitName(unit) if unit == "player" then return characterName end end
function GetCVar(name) if name == "realmName" then return "Microbot Vanilla" end end
function GetNumTradeSkills() return table.getn(tradeRows) end
function GetTradeSkillLine() return profession end
function GetTradeSkillInfo(index)
  local row = tradeRows[index]
  if not row then return nil end
  return row.name, row.kind, row.available, row.expanded
end
function GetTradeSkillItemLink(index)
  local row = tradeRows[index]
  return row and row.link or nil
end
function GetTradeSkillCooldown(index)
  local row = tradeRows[index]
  return row and row.cooldown or nil
end
function GetContainerNumSlots(bag)
  return bagRows[bag] and table.getn(bagRows[bag]) or 0
end
function GetContainerItemLink(bag, slot)
  local row = bagRows[bag] and bagRows[bag][slot]
  return row and row.link or nil
end
function GetContainerItemCooldown(bag, slot)
  local row = bagRows[bag] and bagRows[bag][slot]
  if not row then return 0, 0, 0 end
  local enabled = row.enabled
  if enabled == nil then enabled = 1 end
  return row.start, row.duration, enabled
end
function RequestRaidInfo() raidInfoRequests = raidInfoRequests + 1 end
function GetNumSavedInstances() return table.getn(raidRows) end
function GetSavedInstanceInfo(index)
  local row = raidRows[index]
  return row and row.name, row and row.id, row and row.reset
end
function CastSpellByName(name) table.insert(castCalls, name) end
function DoTradeSkill(index, amount) table.insert(craftCalls, { index, amount }) end
function UseContainerItem(bag, slot) table.insert(itemUseCalls, { bag, slot }) end
function CursorHasItem() return cursorHasItem end
MerchantFrame = { IsShown = function() return merchantOpen or unsafeWindows.merchant end }
BankFrame = { IsShown = function() return unsafeWindows.bank end }
TradeFrame = { IsShown = function() return unsafeWindows.trade end }
AuctionFrame = { IsShown = function() return unsafeWindows.auction end }
MailFrame = { IsShown = function() return unsafeWindows.mail end }
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) table.insert(chat, message) end }

ShirsLazyTrix = {}
ShirsLazyTrixDB = { showCooldownPanel = true, notifyOtherMooncloth = true, notifyOtherArcanite = true, notifyOtherSalt = true, cooldownsByCharacter = {} }

dofile(root .. "/ShirsLazyTrix_Cooldowns.lua")

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "value mismatch") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local key = ShirsLazyTrix.CooldownCharacterKey()
assertEqual(key, "Microbot Vanilla\031Shirina", "character key")

raidRows = {
  { name = "Molten Core", id = "A1", reset = 3600 },
  { name = "Onyxia's Lair", id = "B2", reset = 0 },
}
assertEqual(ShirsLazyTrix.RequestRaidInfo(), true, "raid info request")
assertEqual(raidInfoRequests, 1, "raid info request count")
assertEqual(ShirsLazyTrix.UpdateRaidInfoObservations(now), true, "raid info observation")
local raidState = ShirsLazyTrix.GetCurrentRaidInfo()
assertEqual(raidState.known, true, "raid info state known")
assertEqual(table.getn(raidState.instances), 2, "raid row count")
assertEqual(raidState.instances[1].name, "Molten Core", "raid instance name")
assertEqual(raidState.instances[1].id, "A1", "raid instance id")
assertEqual(raidState.instances[1].readyAt, now + 3600, "raid absolute reset time")
assertEqual(ShirsLazyTrix.FormatRaidInfoStatus(raidState.instances[1], now), "1h 0m", "raid reset status")
assertEqual(ShirsLazyTrix.FormatRaidInfoStatus(raidState.instances[2], now), "Ready", "ready raid status")
raidRows[2].reset = "invalid"
assertEqual(ShirsLazyTrix.UpdateRaidInfoObservations(now), false, "malformed raid row fails closed")
assertEqual(table.getn(raidState.instances), 2, "malformed raid row preserves prior snapshot")
raidRows = {}
assertEqual(ShirsLazyTrix.UpdateRaidInfoObservations(now), true, "empty raid response observation")
assertEqual(table.getn(raidState.instances), 0, "empty raid response clears snapshot")
local readyDisplayRows = ShirsLazyTrix.GetRaidInfoDisplayEntries(true)
assertEqual(table.getn(readyDisplayRows), 7, "unsaved raid catalog row count")
assertEqual(readyDisplayRows[1].name, "Molten Core", "first unsaved raid catalog row")
assertEqual(readyDisplayRows[1].ready, true, "unsaved raid row is marked ready")
raidRows = { { name = "The Ruins of Ahn'Qiraj", id = "AQ20", reset = 3600 } }
assertEqual(ShirsLazyTrix.UpdateRaidInfoObservations(now), true, "saved raid alias observation")
local aliasDisplayRows = ShirsLazyTrix.GetRaidInfoDisplayEntries(true)
assertEqual(table.getn(aliasDisplayRows), 7, "saved raid alias avoids duplicate ready row")
local canonicalReadyRows = 0
local aliasIndex
for aliasIndex = 1, table.getn(aliasDisplayRows) do
  if aliasDisplayRows[aliasIndex].name == "Ruins of Ahn'Qiraj" and aliasDisplayRows[aliasIndex].ready then
    canonicalReadyRows = canonicalReadyRows + 1
  end
end
assertEqual(canonicalReadyRows, 0, "saved raid alias suppresses canonical ready row")
assertEqual(table.getn(ShirsLazyTrix.GetRaidInfoDisplayEntries(false)), 1, "ready toggle off keeps saved rows only")
raidRows = {}
assertEqual(ShirsLazyTrix.UpdateRaidInfoObservations(now), true, "empty raid response restores ready catalog state")
ShirsLazyTrixDB.cooldownsByCharacter["Microbot Vanilla\031Alfa"] = {
  raidInfo = {
    known = true,
    instances = { { name = "Molten Core", id = "X9", readyAt = now + 7200 } },
  },
}
local otherRaidRows = ShirsLazyTrix.GetRaidInfoCharacterStatuses("Molten Core", now)
assertEqual(table.getn(otherRaidRows), 1, "other-character raid hover row count")
assertEqual(otherRaidRows[1].owner, "Alfa", "other-character raid owner")
assertEqual(otherRaidRows[1].status, "2h 0m", "other-character raid status")

assertEqual(ShirsLazyTrix.FormatCooldownStatus(nil, now), "Not known", "unknown status")
assertEqual(ShirsLazyTrix.FormatCooldownStatus({ known = true, readyAt = now - 1 }, now), "Ready", "ready status")
assertEqual(ShirsLazyTrix.FormatCooldownStatus({ known = true, readyAt = now + 93784 }, now), "1d 2h", "day/hour status")
assertEqual(ShirsLazyTrix.FormatCooldownStatus({ known = true, readyAt = now + 3700 }, now), "1h 1m", "hour/minute status")
assertEqual(ShirsLazyTrix.FormatCooldownStatus({ known = true, readyAt = now + 59 }, now), "59s", "seconds status")

ShirsLazyTrixDB.cooldownsByCharacter = {
  ["Microbot Vanilla\031Alfa"] = { mooncloth = { known = true, readyAt = now + 65 } },
  ["Microbot Vanilla\031Beta"] = { mooncloth = { known = true, readyAt = now } },
  ["Other Realm\031Gamma"] = {},
  malformed = { mooncloth = { known = true, readyAt = now } },
}
local accountRows = ShirsLazyTrix.GetCooldownCharacterStatuses("mooncloth", now)
assertEqual(table.getn(accountRows), 3, "account-wide cooldown hover row count")
assertEqual(accountRows[1].owner, "Alfa", "same-realm cooldown owner")
assertEqual(accountRows[1].status, "1m 5s", "same-realm live cooldown status")
assertEqual(accountRows[2].owner, "Beta", "second same-realm cooldown owner")
assertEqual(accountRows[2].status, "Ready", "ready account cooldown status")
assertEqual(accountRows[3].owner, "Gamma (Other Realm)", "other-realm cooldown owner")
assertEqual(accountRows[3].status, "Not known", "unknown account cooldown status")
ShirsLazyTrixDB.cooldownsByCharacter = {}

tradeRows = {
  { name = "Mooncloth", kind = "optimal", available = 1, link = "|cffffffff|Hitem:14342:0:0:0|h[Mooncloth]|h|r", cooldown = 172800 },
}
ShirsLazyTrix.UpdateTradeSkillCooldowns(now)
local state = ShirsLazyTrix.GetCurrentCooldowns()
assertEqual(state.mooncloth.known, true, "Mooncloth learned")
assertEqual(state.mooncloth.readyAt, now + 172800, "Mooncloth ready time")
assertEqual(state.arcanite, nil, "unseen Arcanite must remain unknown")

-- While the profession window stays open, polling must catch a cooldown that starts
-- after the final TRADE_SKILL_UPDATE event (including crafts started outside LazyTrix).
tradeRows[1].cooldown = 0
ShirsLazyTrix.HandleTradeSkillShown(now)
assertEqual(state.mooncloth.readyAt, now, "open profession starts from ready state")
tradeRows[1].cooldown = 172800
ShirsLazyTrix.HandleCooldownOnUpdate(0.49)
assertEqual(state.mooncloth.readyAt, now, "profession polling waits for its interval")
ShirsLazyTrix.HandleCooldownOnUpdate(0.01)
assertEqual(state.mooncloth.readyAt, now + 172800, "open profession polling observes newly started cooldown")
ShirsLazyTrix.HandleTradeSkillClosed()
tradeRows[1].cooldown = 100
ShirsLazyTrix.HandleCooldownOnUpdate(1)
assertEqual(state.mooncloth.readyAt, now + 172800, "closed profession window is not polled")
ShirsLazyTrix.HandleTradeSkillCooldownEvent(now)
tradeRows[1].cooldown = 200
ShirsLazyTrix.HandleCooldownOnUpdate(1)
assertEqual(state.mooncloth.readyAt, now + 100, "late update after close does not restart profession polling")
state.mooncloth.readyAt = now + 172800

profession = "Alchemy"
tradeRows = {
  { name = "Transmute: Arcanite", kind = "trivial", available = 0, link = "|cffffffff|Hitem:12360:0:0:0|h[Arcanite Bar]|h|r", cooldown = nil },
}
ShirsLazyTrix.UpdateTradeSkillCooldowns(now)
state = ShirsLazyTrix.GetCurrentCooldowns()
assertEqual(state.arcanite.known, true, "Arcanite learned")
assertEqual(state.arcanite.readyAt, now, "nil trade cooldown means ready")
assertEqual(state.mooncloth.readyAt, now + 172800, "other profession state is preserved")

bagRows[0] = {
  { link = "|cff1eff00|Hitem:15846:0:0:0|h[Salt Shaker]|h|r", start = uptime - 60, duration = 259200, enabled = 1 },
}
ShirsLazyTrix.UpdateSaltShakerCooldown(now)
state = ShirsLazyTrix.GetCurrentCooldowns()
assertEqual(state.salt.known, true, "Salt Shaker learned")
assertEqual(state.salt.readyAt, now + 259140, "Salt Shaker absolute ready time")

-- The client's millisecond uptime wraps at 2^32 and must not create a roughly 50-day cooldown.
bagRows[0][1].start = 4294500
bagRows[0][1].duration = 259200
ShirsLazyTrix.UpdateSaltShakerCooldown(now)
local wrappedRemaining = state.salt.readyAt - now
assertEqual(wrappedRemaining > 258232 and wrappedRemaining < 258233, true, "wrapped Salt Shaker cooldown is normalized")

-- A merely future or beyond-wrap start is invalid, not an expired cooldown.
bagRows[0][1].start = 600
bagRows[0][1].duration = 60
assertEqual(ShirsLazyTrix.UpdateSaltShakerCooldown(now), false, "ordinary future Salt Shaker start fails closed")
state.salt = { known = true, readyAt = now }
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, "ordinary future Salt Shaker start cannot use item")
assertEqual(table.getn(itemUseCalls), 0, "ordinary future Salt Shaker start has no item-use call")
bagRows[0][1].start = 4295067.296
bagRows[0][1].duration = 100
assertEqual(ShirsLazyTrix.UpdateSaltShakerCooldown(now), false, "beyond-wrap Salt Shaker start fails closed")
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, "beyond-wrap Salt Shaker start cannot use item")
assertEqual(table.getn(itemUseCalls), 0, "beyond-wrap Salt Shaker start has no item-use call")
bagRows[0][1].start = 4294500
bagRows[0][1].duration = 259200

-- Malformed saved rows are repaired before observations write into them.
state.salt = "malformed"
assertEqual(ShirsLazyTrix.UpdateSaltShakerCooldown(now), true, "malformed Salt Shaker row repair")
assertEqual(type(state.salt), "table", "Salt Shaker row repaired to table")
state.mooncloth = "malformed"
tradeRows = {
  { name = "Mooncloth", kind = "optimal", available = 1, link = "|cffffffff|Hitem:14342:0:0:0|h[Mooncloth]|h|r", cooldown = 172800 },
}
ShirsLazyTrix.UpdateTradeSkillCooldowns(now)
assertEqual(type(state.mooncloth), "table", "Mooncloth row repaired to table")

-- A ready profession click opens the profession but does not craft until the live row is available.
state.arcanite.readyAt = now
tradeRows = {}
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("arcanite"), true, "ready Arcanite click")
assertEqual(castCalls[1], "Alchemy", "Arcanite opens Alchemy")
assertEqual(table.getn(craftCalls), 0, "profession click must not craft without a live recipe row")
tradeRows = {
  { name = "Transmute: Arcanite", kind = "trivial", available = 0, link = "|cffffffff|Hitem:12360:0:0:0|h[Arcanite Bar]|h|r", cooldown = nil },
}
ShirsLazyTrix.HandleTradeSkillClosed()
ShirsLazyTrix.HandleTradeSkillCooldownEvent(now)
assertEqual(table.getn(craftCalls), 1, "profession-switch close must preserve the validated craft")
assertEqual(craftCalls[1][1], 1, "validated profession recipe index")
assertEqual(craftCalls[1][2], 1, "profession click crafts exactly one")
ShirsLazyTrix.HandleTradeSkillCooldownEvent(now)
assertEqual(table.getn(craftCalls), 1, "trade update must not repeat the craft")

-- If the matching profession is already open, the click revalidates immediately.
profession = "Tailoring"
tradeRows = {
  { name = "Mooncloth", kind = "trivial", available = 1, link = "|cffffffff|Hitem:14342:0:0:0|h[Mooncloth]|h|r", cooldown = nil },
}
state.mooncloth.readyAt = now
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("mooncloth"), true, "open Tailoring Mooncloth click")
assertEqual(table.getn(craftCalls), 2, "already-open profession must craft after immediate revalidation")
assertEqual(craftCalls[2][1], 1, "already-open profession recipe index")
assertEqual(craftCalls[2][2], 1, "already-open profession crafts exactly one")

-- A known active cooldown refuses before opening the profession.
state.mooncloth.readyAt = now + 100
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("mooncloth"), false, "cooling Mooncloth click")
assertEqual(table.getn(castCalls), 2, "cooling profession must not open")

-- Salt Shaker is revalidated in the bag and used exactly once only when ready.
local saltLink = "|cff1eff00|Hitem:15846:0:0:0|h[Salt Shaker]|h|r"
local otherItemLink = "|cffffffff|Hitem:6948:0:0:0|h[Hearthstone]|h|r"
local function prepareReadySalt()
  bagRows[0][1] = { link = saltLink, start = 0, duration = 0, enabled = 1 }
  state.salt = { known = true, readyAt = now }
  merchantOpen = false
  cursorHasItem = false
  local name
  for name in pairs(unsafeWindows) do unsafeWindows[name] = false end
end

local function assertSaltBlocked(label, setup)
  prepareReadySalt()
  local usesBefore = table.getn(itemUseCalls)
  if setup then setup() end
  assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, label)
  assertEqual(table.getn(itemUseCalls), usesBefore, label .. " must not call UseContainerItem")
end

prepareReadySalt()
merchantOpen = true
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, "merchant context blocks Salt Shaker use")
assertEqual(table.getn(itemUseCalls), 0, "merchant context must not sell the Salt Shaker")
merchantOpen = false
cursorHasItem = true
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, "cursor item blocks Salt Shaker use")
assertEqual(table.getn(itemUseCalls), 0, "cursor item context must not alter the Salt Shaker")
cursorHasItem = false
prepareReadySalt()
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), true, "ready Salt Shaker click")
assertEqual(table.getn(itemUseCalls), 1, "Salt Shaker use count")
assertEqual(itemUseCalls[1][1], 0, "Salt Shaker bag")
assertEqual(itemUseCalls[1][2], 1, "Salt Shaker slot")
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, "duplicate ready Salt Shaker click is blocked")
assertEqual(table.getn(itemUseCalls), 1, "duplicate ready click must not reuse Salt Shaker")
uptime = uptime + 4
ShirsLazyTrix.HandleCooldownOnUpdate(0)
bagRows[0][1].start = uptime - 10
bagRows[0][1].duration = 259200
state.salt = { known = true, readyAt = now }
local savedCoolingRead = GetContainerItemCooldown
local coolingReads = 0
GetContainerItemCooldown = function(bag, slot)
  coolingReads = coolingReads + 1
  return savedCoolingRead(bag, slot)
end
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), false, "cooling Salt Shaker click")
assertEqual(coolingReads > 0, true, "cooling Salt Shaker fixture reaches the live cooldown branch")
GetContainerItemCooldown = savedCoolingRead
assertEqual(table.getn(itemUseCalls), 1, "cooling Salt Shaker must not be reused")

-- Every standard item-moving window blocks Salt Shaker use.
local unsafeName
for unsafeName in pairs(unsafeWindows) do
  assertSaltBlocked(unsafeName .. " window blocks Salt Shaker use", function()
    unsafeWindows[unsafeName] = true
  end)
end
assertEqual(table.getn(itemUseCalls), 1, "item-moving windows must not redirect Salt Shaker use")

-- Missing and malformed live APIs fail closed before UseContainerItem.
local savedContainerCooldown = GetContainerItemCooldown
local savedCursorHasItem = CursorHasItem
assertSaltBlocked("missing item cooldown API blocks Salt Shaker use", function() GetContainerItemCooldown = nil end)
assertSaltBlocked("missing cooldown tuple blocks Salt Shaker use", function() GetContainerItemCooldown = function() return nil, nil, nil end end)
assertSaltBlocked("NaN cooldown start blocks Salt Shaker use", function() GetContainerItemCooldown = function() return 0 / 0, 0, 1 end end)
assertSaltBlocked("NaN cooldown duration blocks Salt Shaker use", function() GetContainerItemCooldown = function() return 0, 0 / 0, 1 end end)
assertSaltBlocked("malformed duration blocks Salt Shaker use", function() GetContainerItemCooldown = function() return 0, "invalid", 1 end end)
assertSaltBlocked("disabled cooldown tuple blocks Salt Shaker use", function() GetContainerItemCooldown = function() return 0, 0, 0 end end)
GetContainerItemCooldown = savedContainerCooldown
assertSaltBlocked("missing cursor API blocks Salt Shaker use", function() CursorHasItem = nil end)
CursorHasItem = savedCursorHasItem
assertEqual(table.getn(itemUseCalls), 1, "invalid live data must never use Salt Shaker")

-- Context, slot identity, and cooldown are checked again immediately before use.
assertSaltBlocked("merchant opened during cooldown read blocks use", function()
  GetContainerItemCooldown = function()
    unsafeWindows.merchant = true
    return 0, 0, 1
  end
end)
GetContainerItemCooldown = savedContainerCooldown
assertSaltBlocked("cursor item attached during cooldown read blocks use", function()
  GetContainerItemCooldown = function()
    cursorHasItem = true
    return 0, 0, 1
  end
end)
GetContainerItemCooldown = savedContainerCooldown
assertSaltBlocked("bag slot replaced during cooldown read blocks use", function()
  GetContainerItemCooldown = function()
    bagRows[0][1].link = otherItemLink
    return 0, 0, 1
  end
end)
GetContainerItemCooldown = savedContainerCooldown
assertSaltBlocked("cooldown starting during final revalidation blocks use", function()
  local reads = 0
  GetContainerItemCooldown = function()
    reads = reads + 1
    if reads == 1 then return 0, 0, 1 end
    return uptime, 60, 1
  end
end)
GetContainerItemCooldown = savedContainerCooldown

-- The in-flight guard is set before item use, so synchronous reentry stays single-shot.
prepareReadySalt()
local savedUseContainerItem = UseContainerItem
local reenteredSalt = false
UseContainerItem = function(bag, slot)
  table.insert(itemUseCalls, { bag, slot })
  if not reenteredSalt then
    reenteredSalt = true
    ShirsLazyTrix.ClickProfessionCooldown("salt")
  end
end
local usesBeforeReentry = table.getn(itemUseCalls)
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("salt"), true, "ready Salt Shaker call starts")
assertEqual(table.getn(itemUseCalls), usesBeforeReentry + 1, "synchronous Salt Shaker reentry must stay single-shot")
UseContainerItem = savedUseContainerItem
uptime = uptime + 5
ShirsLazyTrix.HandleCooldownOnUpdate(0)

-- A contradictory live result item ID must override the English recipe-name fallback.
profession = "Tailoring"
tradeRows = {
  { name = "Mooncloth", kind = "trivial", available = 1, link = "|cffffffff|Hitem:99999:0:0:0|h[Wrong Result]|h|r", cooldown = 0 },
}
state.mooncloth = { known = true, readyAt = now }
local craftsBeforeWrongResult = table.getn(craftCalls)
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("mooncloth"), true, "wrong-result row request is handled")
assertEqual(table.getn(craftCalls), craftsBeforeWrongResult, "wrong result item ID must not craft by recipe-name fallback")
uptime = uptime + 5
ShirsLazyTrix.HandleCooldownOnUpdate(0)

-- Malformed profession cooldown data never becomes Ready or reaches DoTradeSkill.
local savedTradeCooldown = GetTradeSkillCooldown
profession = "Tailoring"
tradeRows = {
  { name = "Mooncloth", kind = "trivial", available = 1, link = "|cffffffff|Hitem:14342:0:0:0|h[Mooncloth]|h|r", cooldown = "invalid" },
}
state.mooncloth = { known = true, readyAt = now }
local craftsBeforeInvalid = table.getn(craftCalls)
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("mooncloth"), true, "invalid live trade cooldown request is handled")
assertEqual(table.getn(craftCalls), craftsBeforeInvalid, "invalid trade cooldown must not craft")
assertEqual(state.mooncloth.known, false, "invalid trade cooldown becomes unknown")
tradeRows[1].cooldown = 0 / 0
state.mooncloth = { known = true, readyAt = now }
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("mooncloth"), true, "NaN live trade cooldown request is handled")
assertEqual(table.getn(craftCalls), craftsBeforeInvalid, "NaN trade cooldown must not craft")
GetTradeSkillCooldown = nil
state.mooncloth = { known = true, readyAt = now }
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("mooncloth"), true, "missing live trade cooldown request is handled")
assertEqual(table.getn(craftCalls), craftsBeforeInvalid, "missing trade cooldown API must not craft")
GetTradeSkillCooldown = savedTradeCooldown

-- A malformed saved profession row is repaired before the first click reads fields.
tradeRows[1].cooldown = nil
state.mooncloth = "malformed"
local malformedClickOk, malformedClickResult = pcall(ShirsLazyTrix.ClickProfessionCooldown, "mooncloth")
assertEqual(malformedClickOk, true, "malformed Mooncloth row click must not throw")
assertEqual(malformedClickResult, true, "malformed Mooncloth row click is revalidated")
assertEqual(type(state.mooncloth), "table", "malformed Mooncloth click row repaired")
assertEqual(table.getn(craftCalls), craftsBeforeInvalid + 1, "repaired Mooncloth row crafts exactly once after live validation")

-- Pending requests reject duplicate clicks and expire after the bounded timeout.
profession = "Alchemy"
tradeRows = {}
state.arcanite = { known = true, readyAt = now }
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("arcanite"), true, "pending craft starts")
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("arcanite"), false, "duplicate pending craft is blocked")
uptime = uptime + 5
ShirsLazyTrix.HandleCooldownOnUpdate(0)
assertEqual(ShirsLazyTrix.ClickProfessionCooldown("arcanite"), true, "expired pending craft can be retried")
uptime = uptime + 5
ShirsLazyTrix.HandleCooldownOnUpdate(0)

-- Cooldown state remains isolated between characters.
characterName = "OtherCharacter"
local otherState = ShirsLazyTrix.GetCurrentCooldowns()
assertEqual(otherState.mooncloth, nil, "other character does not inherit Mooncloth state")
characterName = "Shirina"
state = ShirsLazyTrix.GetCurrentCooldowns()
assertEqual(type(state.mooncloth), "table", "original character state remains available")

-- Login notifications include ready cooldowns for other saved characters only.
ShirsLazyTrixDB.cooldownsByCharacter["Microbot Vanilla\031OtherCharacter"] = {
  mooncloth = { known = true, readyAt = now - 1 },
  arcanite = { known = true, readyAt = now + 100 },
  salt = { known = true, readyAt = now },
}
ShirsLazyTrixDB.cooldownsByCharacter["Other Realm\031RemoteCharacter"] = {
  arcanite = { known = true, readyAt = now - 10 },
}
ShirsLazyTrixDB.cooldownsByCharacter["Microbot Vanilla\031BrokenCharacter"] = "malformed"
ShirsLazyTrixDB.cooldownsByCharacter["   "] = { mooncloth = { known = true, readyAt = now } }
ShirsLazyTrixDB.cooldownsByCharacter["NoDelimiter"] = { mooncloth = { known = true, readyAt = now } }
ShirsLazyTrixDB.cooldownsByCharacter["\031BlankRealm"] = { mooncloth = { known = true, readyAt = now } }
ShirsLazyTrixDB.cooldownsByCharacter["Realm\031Name\031Extra"] = { mooncloth = { known = true, readyAt = now } }
state.mooncloth = { known = true, readyAt = now - 1 }
local chatBeforeReadyNotice = table.getn(chat)
assertEqual(ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters(now), 3, "other-character ready notification count")
assertEqual(table.getn(chat), chatBeforeReadyNotice + 3, "one chat notice per ready cooldown")
assertEqual(chat[chatBeforeReadyNotice + 1], "|cff73cfffLazyTrix:|r OtherCharacter: Mooncloth is ready.", "same-realm ready notice")
assertEqual(chat[chatBeforeReadyNotice + 2], "|cff73cfffLazyTrix:|r OtherCharacter: Salt Shaker is ready.", "same-realm Salt Shaker notice")
assertEqual(chat[chatBeforeReadyNotice + 3], "|cff73cfffLazyTrix:|r RemoteCharacter (Other Realm): Transmute: Arcanite is ready.", "cross-realm ready notice")

ShirsLazyTrixDB.notifyOtherMooncloth = false
ShirsLazyTrixDB.notifyOtherArcanite = false
ShirsLazyTrixDB.notifyOtherSalt = false
chatBeforeReadyNotice = table.getn(chat)
assertEqual(ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters(now), 0, "all other-character reminders can be disabled")
assertEqual(table.getn(chat), chatBeforeReadyNotice, "disabled reminders add no chat messages")

ShirsLazyTrixDB.notifyOtherMooncloth = true
assertEqual(ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters(now), 1, "Mooncloth reminder can be enabled alone")
assertEqual(chat[table.getn(chat)], "|cff73cfffLazyTrix:|r OtherCharacter: Mooncloth is ready.", "Mooncloth-only reminder")
ShirsLazyTrixDB.notifyOtherMooncloth = false
ShirsLazyTrixDB.notifyOtherArcanite = true
assertEqual(ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters(now), 1, "Arcanite reminder can be enabled alone")
assertEqual(chat[table.getn(chat)], "|cff73cfffLazyTrix:|r RemoteCharacter (Other Realm): Transmute: Arcanite is ready.", "Arcanite-only reminder")
ShirsLazyTrixDB.notifyOtherArcanite = false
ShirsLazyTrixDB.notifyOtherSalt = true
assertEqual(ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters(now), 1, "Salt Shaker reminder can be enabled alone")
assertEqual(chat[table.getn(chat)], "|cff73cfffLazyTrix:|r OtherCharacter: Salt Shaker is ready.", "Salt-only reminder")

-- Position validation accepts sane values and rejects malformed saved data.
local point, relativePoint, x, y = ShirsLazyTrix.NormalizeCooldownPanelPosition("TOPLEFT", "TOPLEFT", 42, -77)
assertEqual(point, "TOPLEFT", "saved point")
assertEqual(relativePoint, "TOPLEFT", "saved relative point")
assertEqual(x, 42, "saved x")
assertEqual(y, -77, "saved y")
point, relativePoint, x, y = ShirsLazyTrix.NormalizeCooldownPanelPosition("BAD", "CENTER", "x", 1)
assertEqual(point, "CENTER", "invalid point fallback")
assertEqual(relativePoint, "CENTER", "invalid relative point fallback")
assertEqual(x, 0, "invalid x fallback")
assertEqual(y, 80, "invalid y fallback")
point, relativePoint, x, y = ShirsLazyTrix.NormalizeCooldownPanelPosition("CENTER", "CENTER", 0 / 0, 5)
assertEqual(y, 80, "NaN x forces fallback instead of preserving valid y")
point, relativePoint, x, y = ShirsLazyTrix.NormalizeCooldownPanelPosition("CENTER", "CENTER", 5, 0 / 0)
assertEqual(x, 0, "NaN y forces fallback instead of preserving valid x")

print("cooldown-state-and-formatting: PASS")
print("cooldown-trade-and-item-observation: PASS")
print("cooldown-one-click-revalidation: PASS")
print("cooldown-panel-position-validation: PASS")
