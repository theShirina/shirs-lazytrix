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
ShirsLazyTrix = {
  EnsureDatabase = function() end,
  CreateUI = function() end,
  HandleGossipShow = function() end,
  HandleQuestGreeting = function() end,
  HandleQuestDetail = function() end,
  HandleQuestProgress = function() end,
  HandleQuestComplete = function() end,
  HandleQuestLogUpdate = function() end,
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
assert(type(frame.scripts.OnUpdate) == "function", "merchant update driver is missing")

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
