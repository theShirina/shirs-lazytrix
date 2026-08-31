local frame = CreateFrame("Frame", "ShirsLazyTrixEventFrame")
local readyCooldownLoginNotified = false
local savedVariablesLoaded = false
local enteredWorld = false
local readyCooldownLoginDelay = nil
local READY_NOTICE_EPSILON = 0.000001
local MAX_EVENT_ELAPSED = 86400

local function scheduleReadyCooldownLoginNotice()
  if savedVariablesLoaded and enteredWorld and not readyCooldownLoginNotified and not readyCooldownLoginDelay then
    readyCooldownLoginDelay = 10
  end
end

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_FINISHED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")
frame:RegisterEvent("RESURRECT_REQUEST")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_INSTANCE_INFO")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BAG_UPDATE_COOLDOWN")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_UPDATE")
frame:RegisterEvent("TRADE_SKILL_CLOSE")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

frame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    savedVariablesLoaded = true
    ShirsLazyTrix.EnsureDatabase()
    ShirsLazyTrix.CreateUI()
    ShirsLazyTrix.InitializeCooldowns()
    ShirsLazyTrix.InitializeRaidInfo()
    ShirsLazyTrix.InstallItemIDTooltipHooks()
    scheduleReadyCooldownLoginNotice()
  elseif event == "PLAYER_ENTERING_WORLD" then
    enteredWorld = true
    ShirsLazyTrix.InitializeCooldowns()
    ShirsLazyTrix.InitializeRaidInfo()
    ShirsLazyTrix.RefreshCooldownPanelVisibility()
    scheduleReadyCooldownLoginNotice()
  elseif event == "UPDATE_INSTANCE_INFO" then
    ShirsLazyTrix.HandleRaidInfoUpdate()
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    ShirsLazyTrix.RefreshCooldownPanelVisibility()
    ShirsLazyTrix.RefreshRaidInfoPanelVisibility()
  elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_COOLDOWN" then
    ShirsLazyTrix.RefreshCooldownObservations()
  elseif event == "TRADE_SKILL_SHOW" then
    ShirsLazyTrix.HandleTradeSkillShown()
  elseif event == "TRADE_SKILL_UPDATE" then
    ShirsLazyTrix.HandleTradeSkillCooldownEvent()
  elseif event == "TRADE_SKILL_CLOSE" then
    ShirsLazyTrix.HandleTradeSkillClosed()
  elseif event == "PLAYER_REGEN_DISABLED" then
    ShirsLazyTrix.SetCooldownPanelCombatState(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    ShirsLazyTrix.SetCooldownPanelCombatState(false)
  elseif event == "GOSSIP_SHOW" then
    if not ShirsLazyTrix.TryAutoOpenTrainer() then
      ShirsLazyTrix.HandleGossipShow()
    end
  elseif event == "QUEST_GREETING" then
    ShirsLazyTrix.HandleQuestGreeting()
  elseif event == "QUEST_DETAIL" then
    ShirsLazyTrix.HandleQuestDetail()
  elseif event == "QUEST_PROGRESS" then
    ShirsLazyTrix.HandleQuestProgress()
  elseif event == "QUEST_COMPLETE" then
    ShirsLazyTrix.HandleQuestComplete()
  elseif event == "QUEST_FINISHED" then
    ShirsLazyTrix.HandleQuestFinished()
  elseif event == "QUEST_LOG_UPDATE" then
    ShirsLazyTrix.HandleQuestLogUpdate()
  elseif event == "RESURRECT_REQUEST" then
    ShirsLazyTrix.TryAutoAcceptResurrection()
  elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
    ShirsLazyTrix.HandleStealthBuffMessage(arg1)
  elseif event == "CHAT_MSG_WHISPER" then
    ShirsLazyTrix.HandleInviteChat(arg1, arg2, "WHISPER")
  elseif event == "CHAT_MSG_GUILD" then
    ShirsLazyTrix.HandleInviteChat(arg1, arg2, "GUILD")
  elseif event == "MERCHANT_SHOW" then
    ShirsLazyTrix.TryAutoRepairAll()
    ShirsLazyTrix.StartAutoGraySale()
  elseif event == "MERCHANT_CLOSED" then
    ShirsLazyTrix.CancelGraySale()
  end
end)

local merchantElapsed = 0
frame:SetScript("OnUpdate", function()
  local elapsed = arg1 or 0
  if type(elapsed) ~= "number" or not (elapsed > 0 and elapsed <= MAX_EVENT_ELAPSED) then
    elapsed = 0
  end
  ShirsLazyTrix.HandleCooldownOnUpdate(elapsed)
  if readyCooldownLoginDelay then
    readyCooldownLoginDelay = readyCooldownLoginDelay - elapsed
    if readyCooldownLoginDelay <= READY_NOTICE_EPSILON then
      readyCooldownLoginDelay = nil
      readyCooldownLoginNotified = true
      ShirsLazyTrix.NotifyReadyCooldownsForOtherCharacters()
    end
  end
  if not ShirsLazyTrix.GetGraySaleState() then
    merchantElapsed = 0
    return
  end

  merchantElapsed = merchantElapsed + elapsed
  if merchantElapsed < 0.25 then return end
  merchantElapsed = 0
  ShirsLazyTrix.SellNextGray()
end)

SLASH_SHIRSLAZYTRIX1 = "/lazytrix"
SLASH_SHIRSLAZYTRIX2 = "/slt"
SlashCmdList["SHIRSLAZYTRIX"] = function()
  ShirsLazyTrix.ToggleSettings()
end
