-- Event wiring contract for Shir's LazyTrix 0.0.5

local root = arg and arg[1] or "."
local path = root .. "/ShirsLazyTrix.lua"
local file = io.open(path, "rb")
if not file then error("missing ShirsLazyTrix.lua", 2) end
local source = file:read("*a")
file:close()

local required = {
  'RegisterEvent("VARIABLES_LOADED")',
  'RegisterEvent("GOSSIP_SHOW")',
  'RegisterEvent("QUEST_GREETING")',
  'RegisterEvent("QUEST_DETAIL")',
  'RegisterEvent("QUEST_PROGRESS")',
  'RegisterEvent("QUEST_COMPLETE")',
  'RegisterEvent("QUEST_LOG_UPDATE")',
  'RegisterEvent("MERCHANT_SHOW")',
  'RegisterEvent("MERCHANT_CLOSED")',
  'RegisterEvent("RESURRECT_REQUEST")',
  'RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")',
  'ShirsLazyTrix.HandleGossipShow()',
  'ShirsLazyTrix.TryAutoOpenTrainer()',
  'ShirsLazyTrix.HandleQuestGreeting()',
  'ShirsLazyTrix.HandleQuestDetail()',
  'ShirsLazyTrix.HandleQuestProgress()',
  'ShirsLazyTrix.HandleQuestComplete()',
  'ShirsLazyTrix.HandleQuestLogUpdate()',
  'ShirsLazyTrix.TryAutoAcceptResurrection()',
  'ShirsLazyTrix.HandleStealthBuffMessage(arg1)',
  'ShirsLazyTrix.StartAutoGraySale()',
  'ShirsLazyTrix.CancelGraySale()',
  'ShirsLazyTrix.SellNextGray()',
  'SLASH_SHIRSLAZYTRIX1 = "/lazytrix"',
  'SLASH_SHIRSLAZYTRIX2 = "/slt"',
}

local i
for i = 1, table.getn(required) do
  if not string.find(source, required[i], 1, true) then
    error("missing event contract: " .. required[i], 2)
  end
end

if string.find(source, 'RegisterEvent("QUEST_FINISHED")', 1, true) then
  error("QUEST_FINISHED must not clear incomplete turn-in observations", 2)
end
if string.find(source, "InstallRewardHook", 1, true) then
  error("repeatable reward hook must be removed", 2)
end

print("event-wiring: PASS")
print("event-repeatable-hook-removed: PASS")
