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
ShirsLazyTrix = {
  EnsureDatabase = function() end,
  CreateUI = function() end,
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
}
SlashCmdList = {}

assert(loadfile(root .. "/ShirsLazyTrix.lua"))()
local frame = frames[1]
assert(frame.events.MERCHANT_SHOW, "MERCHANT_SHOW is not registered")
assert(frame.events.MERCHANT_CLOSED, "MERCHANT_CLOSED is not registered")
assert(frame.events.RESURRECT_REQUEST, "RESURRECT_REQUEST is not registered")
assert(frame.events.CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS, "stealth buff chat event is not registered")
assert(type(frame.scripts.OnUpdate) == "function", "merchant update driver is missing")

event = "RESURRECT_REQUEST"
frame.scripts.OnEvent()
assert(merchantOrder[1] == "resurrection", "pending resurrection event was not dispatched")
merchantOrder = {}

event = "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"
arg1 = "You gain Stealth."
frame.scripts.OnEvent()
assert(merchantOrder[1] == "stealth:You gain Stealth.", "stealth buff message was not dispatched")
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

print("MERCHANT_EVENT_DRIVER_TEST=PASS")
