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
  'RegisterEvent("QUEST_FINISHED")',
  'RegisterEvent("QUEST_LOG_UPDATE")',
  'RegisterEvent("MERCHANT_SHOW")',
  'RegisterEvent("MERCHANT_CLOSED")',
  'RegisterEvent("RESURRECT_REQUEST")',
  'RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")',
  'RegisterEvent("CHAT_MSG_WHISPER")',
  'RegisterEvent("CHAT_MSG_GUILD")',
  'RegisterEvent("PLAYER_ENTERING_WORLD")',
  'RegisterEvent("BAG_UPDATE")',
  'RegisterEvent("BAG_UPDATE_COOLDOWN")',
  'RegisterEvent("TRADE_SKILL_SHOW")',
  'RegisterEvent("TRADE_SKILL_UPDATE")',
  'RegisterEvent("TRADE_SKILL_CLOSE")',
  'RegisterEvent("ZONE_CHANGED_NEW_AREA")',
  'ShirsLazyTrix.HandleGossipShow()',
  'ShirsLazyTrix.TryAutoOpenTrainer()',
  'ShirsLazyTrix.HandleQuestGreeting()',
  'ShirsLazyTrix.HandleQuestDetail()',
  'ShirsLazyTrix.HandleQuestProgress()',
  'ShirsLazyTrix.HandleQuestComplete()',
  'ShirsLazyTrix.HandleQuestLogUpdate()',
  'ShirsLazyTrix.TryAutoAcceptResurrection()',
  'ShirsLazyTrix.HandleStealthBuffMessage(arg1)',
  'ShirsLazyTrix.HandleInviteChat(arg1, arg2, "WHISPER")',
  'ShirsLazyTrix.HandleInviteChat(arg1, arg2, "GUILD")',
  'ShirsLazyTrix.StartAutoGraySale()',
  'ShirsLazyTrix.CancelGraySale()',
  'ShirsLazyTrix.SellNextGray()',
  'ShirsLazyTrix.InitializeCooldowns()',
  'ShirsLazyTrix.RefreshCooldownObservations()',
  'ShirsLazyTrix.HandleTradeSkillCooldownEvent()',
  'ShirsLazyTrix.HandleTradeSkillClosed()',
  'ShirsLazyTrix.HandleCooldownOnUpdate(elapsed)',
  'readyCooldownLoginDelay = 10',
  'ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters()',
  'ShirsLazyTrix.RefreshCooldownPanelVisibility()',
  'SLASH_SHIRSLAZYTRIX1 = "/lazytrix"',
  'SLASH_SHIRSLAZYTRIX2 = "/slt"',
}

local i
for i = 1, table.getn(required) do
  if not string.find(source, required[i], 1, true) then
    error("missing event contract: " .. required[i], 2)
  end
end

if string.find(source, "InstallRewardHook", 1, true) then
  error("repeatable reward hook must be removed", 2)
end

print("event-wiring: PASS")
print("event-repeatable-hook-removed: PASS")
