-- Shir's LazyTrix event-driver runtime tests for Lua 5.0.3

local root = arg and arg[1] or "."
local frames = {}

function CreateFrame()
  local frame = { events = {}, scripts = {} }
  function frame:RegisterEvent(name) self.events[name] = true end
  function frame:SetScript(name, handler) self.scripts[name] = handler end
  table.insert(frames, frame)
  return frame
end

local starts = 0
local cancels = 0
local ticks = 0
local saleActive = false
local merchantOrder = {}
local trainerGossipConsumed = false
local gossipHandled = 0
local cooldownInitializations = 0
local raidInfoInitializations = 0
local raidInfoUpdates = 0
local cooldownLoginNotices = 0
local cooldownBagRefreshes = 0
local cooldownTradeRefreshes = 0
local cooldownTradeShows = 0
local cooldownTradeCloses = 0
local cooldownUpdateElapsed = 0
local cooldownCombatStates = {}
local cooldownVisibilityRefreshes = 0
local tooltipHookInitializations = 0
ShirsLazyTrix = {
  EnsureDatabase = function() end,
  CreateUI = function() end,
  InstallItemIDTooltipHooks = function()
    tooltipHookInitializations = tooltipHookInitializations + 1
  end,
  HandleGossipShow = function()
    gossipHandled = gossipHandled + 1
    table.insert(merchantOrder, "quest-gossip")
  end,
  TryAutoOpenTrainer = function()
    table.insert(merchantOrder, "trainer-gossip")
    return trainerGossipConsumed
  end,
  HandleQuestGreeting = function() end,
  HandleQuestDetail = function() end,
  HandleQuestProgress = function() end,
  HandleQuestComplete = function() end,
  HandleQuestLogUpdate = function() end,
  TryAutoAcceptResurrection = function()
    table.insert(merchantOrder, "resurrection")
  end,
  HandleStealthBuffMessage = function(message)
    table.insert(merchantOrder, "stealth:" .. tostring(message))
  end,
  HandleInviteChat = function(message, sender, channel)
    table.insert(merchantOrder, "invite:" .. channel .. ":" .. tostring(sender) .. ":" .. tostring(message))
  end,
  ToggleSettings = function() end,
  TryAutoRepairAll = function()
    table.insert(merchantOrder, "repair")
  end,
  StartAutoGraySale = function()
    table.insert(merchantOrder, "sale")
    starts = starts + 1
    saleActive = true
  end,
  CancelGraySale = function()
    cancels = cancels + 1
    saleActive = false
  end,
  GetGraySaleState = function()
    if saleActive then return {} end
    return nil
  end,
  SellNextGray = function()
    ticks = ticks + 1
  end,
  InitializeCooldowns = function()
    cooldownInitializations = cooldownInitializations + 1
  end,
  InitializeRaidInfo = function()
    raidInfoInitializations = raidInfoInitializations + 1
  end,
  HandleRaidInfoUpdate = function()
    raidInfoUpdates = raidInfoUpdates + 1
  end,
  NotifyReadyCooldownsForOtherCharacters = function()
    cooldownLoginNotices = cooldownLoginNotices + 1
  end,
  RefreshCooldownObservations = function()
    cooldownBagRefreshes = cooldownBagRefreshes + 1
  end,
  HandleTradeSkillCooldownEvent = function()
    cooldownTradeRefreshes = cooldownTradeRefreshes + 1
  end,
  HandleTradeSkillShown = function()
    cooldownTradeShows = cooldownTradeShows + 1
  end,
  HandleTradeSkillClosed = function()
    cooldownTradeCloses = cooldownTradeCloses + 1
  end,
  HandleCooldownOnUpdate = function(elapsed)
    cooldownUpdateElapsed = cooldownUpdateElapsed + elapsed
  end,
  SetCooldownPanelCombatState = function(active)
    table.insert(cooldownCombatStates, active)
  end,
  RefreshCooldownPanelVisibility = function()
    cooldownVisibilityRefreshes = cooldownVisibilityRefreshes + 1
  end,
  RefreshRaidInfoPanelVisibility = function()
    cooldownVisibilityRefreshes = cooldownVisibilityRefreshes + 1
  end,
}
SlashCmdList = {}

assert(loadfile(root .. "/ShirsLazyTrix.lua"))()
local frame = frames[1]
assert(frame.events.MERCHANT_SHOW, "MERCHANT_SHOW is not registered")
assert(frame.events.MERCHANT_CLOSED, "MERCHANT_CLOSED is not registered")
assert(frame.events.RESURRECT_REQUEST, "RESURRECT_REQUEST is not registered")
assert(frame.events.CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS, "stealth buff chat event is not registered")
assert(frame.events.PLAYER_ENTERING_WORLD, "PLAYER_ENTERING_WORLD is not registered")
assert(frame.events.UPDATE_INSTANCE_INFO, "UPDATE_INSTANCE_INFO is not registered")
assert(frame.events.BAG_UPDATE, "BAG_UPDATE is not registered")
assert(frame.events.BAG_UPDATE_COOLDOWN, "BAG_UPDATE_COOLDOWN is not registered")
assert(frame.events.TRADE_SKILL_SHOW, "TRADE_SKILL_SHOW is not registered")
assert(frame.events.TRADE_SKILL_UPDATE, "TRADE_SKILL_UPDATE is not registered")
assert(frame.events.TRADE_SKILL_CLOSE, "TRADE_SKILL_CLOSE is not registered")
assert(frame.events.PLAYER_REGEN_DISABLED, "PLAYER_REGEN_DISABLED is not registered")
assert(frame.events.PLAYER_REGEN_ENABLED, "PLAYER_REGEN_ENABLED is not registered")
assert(frame.events.ZONE_CHANGED_NEW_AREA, "ZONE_CHANGED_NEW_AREA is not registered")
assert(type(frame.scripts.OnUpdate) == "function", "merchant update driver is missing")

event = "PLAYER_ENTERING_WORLD"
frame.scripts.OnEvent()
assert(cooldownLoginNotices == 0, "other-character notices ran before SavedVariables loaded")
event = "VARIABLES_LOADED"
frame.scripts.OnEvent()
assert(cooldownInitializations == 2, "cooldowns were not initialized after SavedVariables")
assert(raidInfoInitializations == 2, "raid info was not initialized after SavedVariables")
assert(tooltipHookInitializations == 1, "tooltip hooks were not refreshed after SavedVariables loaded")
event = "PLAYER_ENTERING_WORLD"
frame.scripts.OnEvent()
assert(cooldownInitializations == 3, "cooldowns were not initialized on world entry")
assert(raidInfoInitializations == 3, "raid info was not initialized on world entry")
assert(cooldownLoginNotices == 0, "other-character ready cooldowns were announced without the login delay")
arg1 = -100
frame.scripts.OnUpdate()
assert(cooldownLoginNotices == 0, "negative elapsed changed the login delay")
arg1 = "malformed"
local malformedElapsedOk = pcall(frame.scripts.OnUpdate)
assert(malformedElapsedOk, "malformed elapsed raised an error")
assert(cooldownLoginNotices == 0, "malformed elapsed changed the login delay")
arg1 = 9.999
frame.scripts.OnUpdate()
assert(cooldownLoginNotices == 0, "other-character ready cooldowns were announced before ten seconds")
arg1 = 0.001
frame.scripts.OnUpdate()
assert(cooldownLoginNotices == 1, "other-character ready cooldowns were not announced at ten seconds")
event = "PLAYER_ENTERING_WORLD"
frame.scripts.OnEvent()
assert(cooldownLoginNotices == 1, "other-character ready cooldowns repeated during the same session")
event = "UPDATE_INSTANCE_INFO"
frame.scripts.OnEvent()
assert(raidInfoUpdates == 1, "raid-info update event was not dispatched")
event = "ZONE_CHANGED_NEW_AREA"
frame.scripts.OnEvent()
assert(cooldownVisibilityRefreshes >= 2, "instance visibility was not refreshed on world and zone changes")
cooldownUpdateElapsed = 0
event = "BAG_UPDATE"
frame.scripts.OnEvent()
event = "BAG_UPDATE_COOLDOWN"
frame.scripts.OnEvent()
assert(cooldownBagRefreshes == 2, "bag cooldown observations were not refreshed")
event = "TRADE_SKILL_SHOW"
frame.scripts.OnEvent()
event = "TRADE_SKILL_UPDATE"
frame.scripts.OnEvent()
assert(cooldownTradeShows == 1, "trade-skill show was not dispatched separately")
assert(cooldownTradeRefreshes == 1, "trade cooldown update was not refreshed")
event = "TRADE_SKILL_CLOSE"
frame.scripts.OnEvent()
assert(cooldownTradeCloses == 1, "pending profession craft was not closed")
event = "PLAYER_REGEN_DISABLED"
frame.scripts.OnEvent()
event = "PLAYER_REGEN_ENABLED"
frame.scripts.OnEvent()
assert(cooldownCombatStates[1] == true and cooldownCombatStates[2] == false, "combat visibility state was not dispatched")

event = "RESURRECT_REQUEST"
frame.scripts.OnEvent()
assert(merchantOrder[1] == "resurrection", "pending resurrection event was not dispatched")
merchantOrder = {}

event = "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"
arg1 = "You gain Stealth."
frame.scripts.OnEvent()
assert(merchantOrder[1] == "stealth:You gain Stealth.", "stealth buff message was not dispatched")
merchantOrder = {}

event = "CHAT_MSG_WHISPER"
arg1 = "invite"
arg2 = "Mage"
frame.scripts.OnEvent()
assert(merchantOrder[1] == "invite:WHISPER:Mage:invite", "whisper invite event was not dispatched")
merchantOrder = {}

event = "CHAT_MSG_GUILD"
arg1 = "invite"
arg2 = "Warrior"
frame.scripts.OnEvent()
assert(merchantOrder[1] == "invite:GUILD:Warrior:invite", "guild invite event was not dispatched")
merchantOrder = {}

event = "GOSSIP_SHOW"
trainerGossipConsumed = true
frame.scripts.OnEvent()
assert(table.getn(merchantOrder) == 1 and merchantOrder[1] == "trainer-gossip" and gossipHandled == 0,
  "selected trainer gossip must suppress quest gossip handling")
merchantOrder = {}
trainerGossipConsumed = false
frame.scripts.OnEvent()
assert(table.getn(merchantOrder) == 2 and merchantOrder[1] == "trainer-gossip" and merchantOrder[2] == "quest-gossip" and gossipHandled == 1,
  "unselected trainer gossip must continue to quest gossip handling")
merchantOrder = {}

event = "MERCHANT_SHOW"
frame.scripts.OnEvent()
assert(table.getn(merchantOrder) == 2 and merchantOrder[1] == "repair" and merchantOrder[2] == "sale",
  "vendor open must attempt repair before starting gray-item selling")
assert(starts == 1 and saleActive, "vendor open did not start automatic gray selling")

arg1 = 0.10
frame.scripts.OnUpdate()
assert(cooldownUpdateElapsed == 0.10, "cooldown driver did not run alongside merchant driver")
assert(ticks == 0, "merchant driver sold before the 0.25-second interval")
arg1 = 0.15
frame.scripts.OnUpdate()
assert(ticks == 1, "merchant driver did not sell one stack at the interval")
arg1 = 0.50
frame.scripts.OnUpdate()
assert(ticks == 2, "merchant driver must submit at most one stack per update")

event = "MERCHANT_CLOSED"
frame.scripts.OnEvent()
assert(cancels == 1 and not saleActive, "vendor close did not cancel automatic selling")
arg1 = 1
frame.scripts.OnUpdate()
assert(ticks == 2, "idle merchant driver must not submit sales")
assert(cooldownUpdateElapsed == 1.75, "cooldown driver must keep running while merchant work is idle")

print("MERCHANT_EVENT_DRIVER_TEST=PASS")
print("COOLDOWN_EVENT_DRIVER_TEST=PASS")
