ShirsLazyTrix = ShirsLazyTrix or {}

local SALT_SHAKER_ITEM_ID = 15846
local COOLDOWN_REFRESH_SECONDS = 0.25
local TRADE_SKILL_POLL_SECONDS = 0.5
local PENDING_CRAFT_TIMEOUT = 4
local MAX_COOLDOWN_SECONDS = 31622400
local MAX_UPTIME_SECONDS = 2147483647
local MAX_WALL_TIME = 4102444800
local MAX_READY_TIME = MAX_WALL_TIME + MAX_COOLDOWN_SECONDS
local UPTIME_WRAP_SECONDS = (2 ^ 32) / 1000

local DEFINITIONS = {
  mooncloth = {
    key = "mooncloth",
    label = "Mooncloth",
    profession = "Tailoring",
    resultItemID = 14342,
    recipeName = "Mooncloth",
  },
  arcanite = {
    key = "arcanite",
    label = "Transmute: Arcanite",
    profession = "Alchemy",
    resultItemID = 12360,
    recipeName = "Transmute: Arcanite",
  },
  salt = {
    key = "salt",
    label = "Salt Shaker",
  },
}

local NOTICE_SETTING_KEYS = {
  mooncloth = "notifyOtherMooncloth",
  arcanite = "notifyOtherArcanite",
  salt = "notifyOtherSalt",
}

local VALID_POINTS = {
  TOPLEFT = true,
  TOP = true,
  TOPRIGHT = true,
  LEFT = true,
  CENTER = true,
  RIGHT = true,
  BOTTOMLEFT = true,
  BOTTOM = true,
  BOTTOMRIGHT = true,
}

local pendingCraft = nil
local pendingSaltUse = nil
local refreshElapsed = 0
local tradeSkillOpen = false
local tradeSkillPollElapsed = 0

local function message(text)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cff73cfffLazyTrix:|r " .. text)
  end
end

local function numberInRange(value, minimum, maximum)
  return type(value) == "number" and value >= minimum and value <= maximum
end

local function wallTime(value)
  if numberInRange(value, 0, MAX_WALL_TIME) then return value end
  if type(time) == "function" then
    local current = time()
    if numberInRange(current, 0, MAX_WALL_TIME) then return current end
  end
  return 0
end

local function uptime()
  if type(GetTime) == "function" then
    local current = GetTime()
    if numberInRange(current, 0, MAX_UPTIME_SECONDS) then return current end
  end
  return 0
end

local function extractItemID(link)
  if type(link) ~= "string" then return nil end
  local _, _, value = string.find(link, "item:(%d+)")
  return tonumber(value)
end

local function currentCharacterState()
  if type(ShirsLazyTrixDB) ~= "table" then ShirsLazyTrixDB = {} end
  if type(ShirsLazyTrixDB.cooldownsByCharacter) ~= "table" then
    ShirsLazyTrixDB.cooldownsByCharacter = {}
  end

  local key = ShirsLazyTrix.CooldownCharacterKey()
  if type(ShirsLazyTrixDB.cooldownsByCharacter[key]) ~= "table" then
    ShirsLazyTrixDB.cooldownsByCharacter[key] = {}
  end
  return ShirsLazyTrixDB.cooldownsByCharacter[key]
end

local function setKnownState(key, readyAt, observedAt)
  local state = currentCharacterState()
  if type(state[key]) ~= "table" then state[key] = {} end
  state[key].known = true
  state[key].readyAt = readyAt
  state[key].observedAt = observedAt
  return state[key]
end

local function setUnknownState(key, observedAt)
  local state = currentCharacterState()
  if type(state[key]) ~= "table" then state[key] = {} end
  state[key].known = false
  state[key].readyAt = nil
  state[key].observedAt = observedAt
  return state[key]
end

local function tradeRemaining(index)
  if type(GetTradeSkillCooldown) ~= "function" then return nil, false end
  local remaining = GetTradeSkillCooldown(index)
  if remaining == nil then return 0, true end
  if not numberInRange(remaining, 0, MAX_COOLDOWN_SECONDS) then
    return nil, false
  end
  return remaining, true
end

local function tradeRowDefinition(index, name)
  local link = nil
  if type(GetTradeSkillItemLink) == "function" then
    link = GetTradeSkillItemLink(index)
  end
  local itemID = extractItemID(link)

  local key, definition
  for key, definition in pairs(DEFINITIONS) do
    if definition.resultItemID then
      if itemID then
        if itemID == definition.resultItemID then return definition end
      elseif name == definition.recipeName then
        return definition
      end
    end
  end
  return nil
end

local function scanTradeSkills(now)
  local found = {}
  if type(GetNumTradeSkills) ~= "function" or type(GetTradeSkillInfo) ~= "function" then
    return found
  end

  local count = GetNumTradeSkills()
  if not numberInRange(count, 0, 1000) or count ~= math.floor(count) then
    return found
  end

  local index
  for index = 1, count do
    local name, skillType = GetTradeSkillInfo(index)
    if name and skillType ~= "header" then
      local definition = tradeRowDefinition(index, name)
      if definition then
        local remaining, valid = tradeRemaining(index)
        if valid then
          setKnownState(definition.key, now + remaining, now)
        else
          setUnknownState(definition.key, now)
        end
        found[definition.key] = {
          index = index,
          remaining = remaining or 0,
          valid = valid,
        }
      end
    end
  end
  return found
end

local function findSaltShaker()
  if type(GetContainerNumSlots) ~= "function" or type(GetContainerItemLink) ~= "function" then
    return nil, nil
  end

  local bag, slot
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    if numberInRange(slots, 1, 100) and slots == math.floor(slots) then
      for slot = 1, slots do
        if extractItemID(GetContainerItemLink(bag, slot)) == SALT_SHAKER_ITEM_ID then
          return bag, slot
        end
      end
    end
  end
  return nil, nil
end

local function saltSlotMatches(bag, slot)
  if type(GetContainerItemLink) ~= "function" then return false end
  return extractItemID(GetContainerItemLink(bag, slot)) == SALT_SHAKER_ITEM_ID
end

local function saltRemaining(bag, slot)
  if type(GetContainerItemCooldown) ~= "function" then return nil end
  local start, duration, enabled = GetContainerItemCooldown(bag, slot)
  if enabled ~= 1 and enabled ~= true then return nil end
  if not numberInRange(start, 0, MAX_UPTIME_SECONDS) or
     not numberInRange(duration, 0, MAX_COOLDOWN_SECONDS) then
    return nil
  end
  if start == 0 and duration == 0 then return 0 end
  if start <= 0 or duration <= 0 then return nil end
  local currentUptime = uptime()
  local remaining
  if start > currentUptime then
    if start > UPTIME_WRAP_SECONDS then return nil end
    local elapsedAcrossWrap = UPTIME_WRAP_SECONDS - start + currentUptime
    if elapsedAcrossWrap < 0 or elapsedAcrossWrap > duration then return nil end
    remaining = duration - elapsedAcrossWrap
  else
    remaining = start + duration - currentUptime
  end
  if remaining < 0 then remaining = 0 end
  if not numberInRange(remaining, 0, MAX_COOLDOWN_SECONDS) then return nil end
  return remaining
end

local function frameShown(frame)
  if not frame then return false end
  if type(frame.IsShown) == "function" and frame:IsShown() then return true end
  if type(frame.IsVisible) == "function" and frame:IsVisible() then return true end
  return false
end

local function unsafeSaltShakerContext()
  if type(CursorHasItem) ~= "function" then return true end
  local cursorState = CursorHasItem()
  if cursorState ~= nil and cursorState ~= false then return true end
  return frameShown(MerchantFrame) or
         frameShown(BankFrame) or
         frameShown(TradeFrame) or
         frameShown(AuctionFrame) or
         frameShown(MailFrame)
end

function ShirsLazyTrix.GetCooldownDefinitions()
  return DEFINITIONS
end

function ShirsLazyTrix.CooldownCharacterKey()
  local realm = ""
  local character = ""
  if type(GetCVar) == "function" then realm = GetCVar("realmName") or "" end
  if type(UnitName) == "function" then character = UnitName("player") or "" end
  return realm .. "\031" .. character
end

function ShirsLazyTrix.GetCurrentCooldowns()
  return currentCharacterState()
end

local function parseSavedCharacterKey(savedKey)
  if type(savedKey) ~= "string" then return nil, nil end
  local separator = string.find(savedKey, "\031", 1, true)
  if not separator or separator <= 1 or separator >= string.len(savedKey) then return nil, nil end
  if string.find(savedKey, "\031", separator + 1, true) then return nil, nil end
  local realm = string.sub(savedKey, 1, separator - 1)
  local character = string.sub(savedKey, separator + 1)
  if not string.find(realm, "%S") or not string.find(character, "%S") then return nil, nil end
  return realm, character
end

function ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters(now)
  if type(ShirsLazyTrixDB) ~= "table" or type(ShirsLazyTrixDB.cooldownsByCharacter) ~= "table" then
    return 0
  end

  local observedAt = wallTime(now)
  local currentKey = ShirsLazyTrix.CooldownCharacterKey()
  local currentRealm = ""
  if type(GetCVar) == "function" then currentRealm = GetCVar("realmName") or "" end
  local characterKeys = {}
  local savedKey
  for savedKey in pairs(ShirsLazyTrixDB.cooldownsByCharacter) do
    local savedRealm, savedCharacter = parseSavedCharacterKey(savedKey)
    if savedRealm and savedCharacter and savedKey ~= currentKey then
      table.insert(characterKeys, savedKey)
    end
  end
  table.sort(characterKeys)

  local definitionKeys = { "mooncloth", "arcanite", "salt" }
  local notices = 0
  local i, j
  for i = 1, table.getn(characterKeys) do
    savedKey = characterKeys[i]
    local state = ShirsLazyTrixDB.cooldownsByCharacter[savedKey]
    if type(state) == "table" then
      local realm, character = parseSavedCharacterKey(savedKey)
      if realm and character then
        local owner = character
        if realm ~= "" and realm ~= currentRealm then owner = owner .. " (" .. realm .. ")" end
        for j = 1, table.getn(definitionKeys) do
          local definition = DEFINITIONS[definitionKeys[j]]
          local entry = state[definition.key]
          local settingKey = NOTICE_SETTING_KEYS[definition.key]
          if ShirsLazyTrixDB[settingKey] ~= false and
             type(entry) == "table" and entry.known == true and
             numberInRange(entry.readyAt, 0, MAX_READY_TIME) and entry.readyAt <= observedAt then
            message(owner .. ": " .. definition.label .. " is ready.")
            notices = notices + 1
          end
        end
      end
    end
  end
  return notices
end

function ShirsLazyTrix.FormatCooldownStatus(entry, now)
  if type(entry) ~= "table" or entry.known ~= true or
     not numberInRange(entry.readyAt, 0, MAX_READY_TIME) then
    return "Not known"
  end

  local remaining = math.ceil(entry.readyAt - wallTime(now))
  if remaining <= 0 then return "Ready" end

  local days = math.floor(remaining / 86400)
  if days > 0 then
    local hours = math.floor(math.mod(remaining, 86400) / 3600)
    return days .. "d " .. hours .. "h"
  end

  local hours = math.floor(remaining / 3600)
  if hours > 0 then
    local minutes = math.floor(math.mod(remaining, 3600) / 60)
    return hours .. "h " .. minutes .. "m"
  end

  local minutes = math.floor(remaining / 60)
  if minutes > 0 then
    return minutes .. "m " .. math.mod(remaining, 60) .. "s"
  end
  return remaining .. "s"
end

function ShirsLazyTrix.GetCooldownCharacterStatuses(cooldownKey, now)
  local rows = {}
  if type(cooldownKey) ~= "string" or not DEFINITIONS[cooldownKey] or
     type(ShirsLazyTrixDB) ~= "table" or type(ShirsLazyTrixDB.cooldownsByCharacter) ~= "table" then
    return rows
  end

  local currentRealm = ""
  if type(GetCVar) == "function" then currentRealm = GetCVar("realmName") or "" end
  local savedKey, state
  for savedKey, state in pairs(ShirsLazyTrixDB.cooldownsByCharacter) do
    local realm, character = parseSavedCharacterKey(savedKey)
    if realm and character and type(state) == "table" then
      local owner = character
      if realm ~= currentRealm then owner = owner .. " (" .. realm .. ")" end
      table.insert(rows, {
        owner = owner,
        realm = realm,
        character = character,
        status = ShirsLazyTrix.FormatCooldownStatus(state[cooldownKey], now),
      })
    end
  end
  table.sort(rows, function(left, right)
    if left.realm == currentRealm and right.realm ~= currentRealm then return true end
    if left.realm ~= currentRealm and right.realm == currentRealm then return false end
    if left.realm ~= right.realm then return left.realm < right.realm end
    return left.character < right.character
  end)
  return rows
end

function ShirsLazyTrix.NormalizeCooldownPanelPosition(point, relativePoint, x, y)
  if not VALID_POINTS[point] or not VALID_POINTS[relativePoint] or
     not numberInRange(x, -10000, 10000) or
     not numberInRange(y, -10000, 10000) then
    return "CENTER", "CENTER", 0, 80
  end
  return point, relativePoint, x, y
end

function ShirsLazyTrix.GetCooldownPanelPosition()
  local position = type(ShirsLazyTrixDB) == "table" and ShirsLazyTrixDB.cooldownPanelPosition or nil
  if type(position) ~= "table" then
    return "CENTER", "CENTER", 0, 80
  end
  return ShirsLazyTrix.NormalizeCooldownPanelPosition(
    position.point,
    position.relativePoint,
    position.x,
    position.y
  )
end

function ShirsLazyTrix.SaveCooldownPanelPosition(point, relativePoint, x, y)
  point, relativePoint, x, y = ShirsLazyTrix.NormalizeCooldownPanelPosition(point, relativePoint, x, y)
  ShirsLazyTrixDB.cooldownPanelPosition = {
    point = point,
    relativePoint = relativePoint,
    x = x,
    y = y,
  }
end

function ShirsLazyTrix.UpdateTradeSkillCooldowns(now)
  return scanTradeSkills(wallTime(now))
end

function ShirsLazyTrix.UpdateSaltShakerCooldown(now)
  local observedAt = wallTime(now)
  local bag, slot = findSaltShaker()
  local state = currentCharacterState()
  if type(state.salt) ~= "table" then state.salt = {} end
  state.salt.inBags = bag ~= nil
  if not bag then return false end

  local remaining = saltRemaining(bag, slot)
  if remaining == nil then return false end
  if remaining > 0 then pendingSaltUse = nil end
  setKnownState("salt", observedAt + remaining, observedAt).inBags = true
  return true
end

function ShirsLazyTrix.RefreshCooldownObservations(now)
  ShirsLazyTrix.UpdateSaltShakerCooldown(now)
  if ShirsLazyTrix.RefreshCooldownPanel then ShirsLazyTrix.RefreshCooldownPanel() end
end

function ShirsLazyTrix.ClickProfessionCooldown(key)
  local definition = DEFINITIONS[key]
  if not definition then return false end

  local now = wallTime()
  local state = currentCharacterState()
  local entry = state[key]
  if type(entry) ~= "table" then
    entry = {}
    state[key] = entry
  end
  if entry.known == true then
    if not numberInRange(entry.readyAt, 0, MAX_READY_TIME) then
      entry.known = false
      entry.readyAt = nil
    elseif entry.readyAt > now then
      message(definition.label .. " is still cooling down.")
      return false
    end
  end

  if key == "salt" then
    if pendingSaltUse then
      message("Salt Shaker use is already pending.")
      return false
    end
    if unsafeSaltShakerContext() then
      message("Close merchant, bank, mail, auction, and trade windows and clear the cursor first.")
      return false
    end
    local bag, slot = findSaltShaker()
    if not bag then
      message("Salt Shaker was not found in your bags.")
      return false
    end
    local remaining = saltRemaining(bag, slot)
    if remaining == nil or remaining > 0 then
      if remaining and remaining > 0 then setKnownState("salt", now + remaining, now).inBags = true end
      if remaining == nil then
        setUnknownState("salt", now).inBags = true
        message("Salt Shaker cooldown could not be read.")
      else
        message("Salt Shaker is still cooling down.")
      end
      if ShirsLazyTrix.RefreshCooldownPanel then ShirsLazyTrix.RefreshCooldownPanel() end
      return false
    end
    if unsafeSaltShakerContext() or not saltSlotMatches(bag, slot) then
      message("Salt Shaker use context or bag slot changed; nothing was used.")
      return false
    end
    remaining = saltRemaining(bag, slot)
    if remaining == nil or remaining > 0 then
      if remaining and remaining > 0 then setKnownState("salt", now + remaining, now).inBags = true end
      if remaining == nil then setUnknownState("salt", now).inBags = true end
      message("Salt Shaker cooldown changed; nothing was used.")
      return false
    end
    if unsafeSaltShakerContext() or not saltSlotMatches(bag, slot) then
      message("Salt Shaker use context or bag slot changed; nothing was used.")
      return false
    end
    if type(UseContainerItem) ~= "function" then return false end
    pendingSaltUse = { startedAt = uptime() }
    UseContainerItem(bag, slot)
    message("Salt Shaker use requested.")
    return true
  end

  if pendingCraft then
    message("Another profession craft is already pending.")
    return false
  end
  if type(CastSpellByName) ~= "function" then return false end

  pendingCraft = {
    key = key,
    startedAt = uptime(),
  }
  CastSpellByName(definition.profession)
  if ShirsLazyTrix.HandleTradeSkillCooldownEvent then
    ShirsLazyTrix.HandleTradeSkillCooldownEvent(now)
  end
  return true
end

function ShirsLazyTrix.HandleTradeSkillCooldownEvent(now)
  local observedAt = wallTime(now)
  local found = scanTradeSkills(observedAt)
  if pendingCraft then
    local request = pendingCraft
    local row = found[request.key]
    if row then
      pendingCraft = nil
      if row.valid ~= true then
        message(DEFINITIONS[request.key].label .. " cooldown could not be read.")
      elseif row.remaining > 0 then
        message(DEFINITIONS[request.key].label .. " is still cooling down.")
      elseif type(DoTradeSkill) == "function" then
        DoTradeSkill(row.index, 1)
        message(DEFINITIONS[request.key].label .. " craft requested.")
      end
    end
  end
  if ShirsLazyTrix.RefreshCooldownPanel then ShirsLazyTrix.RefreshCooldownPanel() end
end

function ShirsLazyTrix.HandleTradeSkillShown(now)
  tradeSkillOpen = true
  tradeSkillPollElapsed = 0
  ShirsLazyTrix.HandleTradeSkillCooldownEvent(now)
end

function ShirsLazyTrix.HandleTradeSkillClosed()
  tradeSkillOpen = false
  tradeSkillPollElapsed = 0
  -- Switching professions can close one trade-skill view before opening the next.
  -- Keep the one-craft request until the target recipe appears or the timeout expires.
  if ShirsLazyTrix.RefreshCooldownPanel then ShirsLazyTrix.RefreshCooldownPanel() end
end

function ShirsLazyTrix.HandleCooldownOnUpdate(elapsed)
  refreshElapsed = refreshElapsed + (elapsed or 0)
  if tradeSkillOpen then
    tradeSkillPollElapsed = tradeSkillPollElapsed + (elapsed or 0)
    if tradeSkillPollElapsed >= TRADE_SKILL_POLL_SECONDS then
      tradeSkillPollElapsed = 0
      scanTradeSkills(wallTime())
      if ShirsLazyTrix.RefreshCooldownPanel then ShirsLazyTrix.RefreshCooldownPanel() end
    end
  end
  if pendingCraft and uptime() - pendingCraft.startedAt >= PENDING_CRAFT_TIMEOUT then
    local label = DEFINITIONS[pendingCraft.key].label
    pendingCraft = nil
    message("Could not find the " .. label .. " recipe.")
  end
  if pendingSaltUse and uptime() - pendingSaltUse.startedAt >= PENDING_CRAFT_TIMEOUT then
    pendingSaltUse = nil
  end
  if refreshElapsed >= COOLDOWN_REFRESH_SECONDS then
    refreshElapsed = 0
    if ShirsLazyTrix.RefreshCooldownPanel then ShirsLazyTrix.RefreshCooldownPanel() end
  end
end

function ShirsLazyTrix.InitializeCooldowns()
  currentCharacterState()
  ShirsLazyTrix.UpdateSaltShakerCooldown(wallTime())
  if ShirsLazyTrix.RefreshCooldownPanelVisibility then
    ShirsLazyTrix.RefreshCooldownPanelVisibility()
  end
end
